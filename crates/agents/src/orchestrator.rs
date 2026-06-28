use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use common::NexusResult;
use crate::agent::Agent;
use crate::types::AgentMessage;

pub struct AgentOrchestrator {
    agents: Arc<RwLock<HashMap<String, Arc<dyn Agent>>>>,
    history: Arc<RwLock<Vec<AgentMessage>>>,
}

impl AgentOrchestrator {
    pub fn new() -> Self {
        Self {
            agents: Arc::new(RwLock::new(HashMap::new())),
            history: Arc::new(RwLock::new(Vec::new())),
        }
    }

    pub async fn register(&self, agent: impl Agent + 'static) {
        let name = agent.name().to_string();
        tracing::info!("Registered agent: {} ({})", name, agent.role());
        self.agents.write().await.insert(name, Arc::new(agent));
    }

    pub async fn send(&self, to: &str, message: AgentMessage) -> NexusResult<AgentMessage> {
        let agents = self.agents.read().await;
        let agent = agents.get(to)
            .ok_or_else(|| common::NexusError::Config(format!("Agent '{}' not found", to)))?;

        tracing::info!("Sending message to agent '{}'", to);
        let response = agent.respond(&message).await?;

        // Store in history
        self.history.write().await.push(message);
        self.history.write().await.push(response.clone());

        Ok(response)
    }

    pub async fn broadcast(&self, message: AgentMessage) -> Vec<(String, NexusResult<AgentMessage>)> {
        let agents = self.agents.read().await;
        let mut results = Vec::new();

        for (name, agent) in agents.iter() {
            if name != &message.from_agent {
                let result = agent.respond(&message).await;
                results.push((name.clone(), result));
            }
        }

        results
    }

    pub async fn list_agents(&self) -> Vec<(String, String)> {
        self.agents.read().await
            .iter()
            .map(|(name, agent)| (name.clone(), agent.role().to_string()))
            .collect()
    }

    pub async fn get_history(&self) -> Vec<AgentMessage> {
        self.history.read().await.clone()
    }
}

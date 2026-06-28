use async_trait::async_trait;
use common::NexusResult;
use crate::types::{AgentConfig, AgentMessage, AgentRole};
use llm::OllamaClient;

#[async_trait]
pub trait Agent: Send + Sync {
    fn config(&self) -> &AgentConfig;
    fn name(&self) -> &str { &self.config().name }
    fn role(&self) -> &AgentRole { &self.config().role }

    async fn think(&self, input: &str) -> NexusResult<String>;
    async fn respond(&self, message: &AgentMessage) -> NexusResult<AgentMessage> {
        let response = self.think(&message.content).await?;
        Ok(AgentMessage::new(self.name(), &response, self.role().clone()))
    }
}

pub struct BaseAgent {
    config: AgentConfig,
    client: OllamaClient,
}

impl BaseAgent {
    pub fn new(config: AgentConfig) -> NexusResult<Self> {
        let client = OllamaClient::new(&config.model)?;
        Ok(Self { config, client })
    }

    fn build_prompt(&self, input: &str) -> String {
        format!("{}\n\nUser: {}\nAssistant:", self.config.system_prompt, input)
    }
}

#[async_trait]
impl Agent for BaseAgent {
    fn config(&self) -> &AgentConfig { &self.config }

    async fn think(&self, input: &str) -> NexusResult<String> {
        let prompt = self.build_prompt(input);
        tracing::debug!("Agent '{}' thinking...", self.config.name);
        self.client.ask(&prompt).await
    }
}

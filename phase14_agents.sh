#!/usr/bin/env bash
set -e

echo "🤖 Initializing Phase 14: Agent System..."

# 1. Create 'agents' crate
echo "📦 Creating 'agents' crate..."
mkdir -p crates/agents/src
cd crates/agents
cargo init --lib --vcs none > /dev/null
cd ../..

# 2. Update agents Cargo.toml
cat > crates/agents/Cargo.toml <<'EOF'
[package]
name = "agents"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
llm = { path = "../llm" }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.35", features = ["full"] }
tracing = "0.1"
async-trait = "0.1"
uuid = { version = "1.6", features = ["v4"] }
chrono = "0.4"
EOF

# 3. Create agent types and traits
cat > crates/agents/src/types.rs <<'EOF'
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum AgentRole {
    Architect,
    Coder,
    Reviewer,
    Tester,
    Researcher,
    Custom(String),
}

impl std::fmt::Display for AgentRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AgentRole::Architect => write!(f, "Architect"),
            AgentRole::Coder => write!(f, "Coder"),
            AgentRole::Reviewer => write!(f, "Reviewer"),
            AgentRole::Tester => write!(f, "Tester"),
            AgentRole::Researcher => write!(f, "Researcher"),
            AgentRole::Custom(name) => write!(f, "{}", name),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentMessage {
    pub id: String,
    pub from_agent: String,
    pub to_agent: Option<String>,
    pub content: String,
    pub role: AgentRole,
    pub timestamp: DateTime<Utc>,
    pub metadata: serde_json::Value,
}

impl AgentMessage {
    pub fn new(from: &str, content: &str, role: AgentRole) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            from_agent: from.to_string(),
            to_agent: None,
            content: content.to_string(),
            role,
            timestamp: Utc::now(),
            metadata: serde_json::json!({}),
        }
    }

    pub fn with_metadata(mut self, key: &str, value: serde_json::Value) -> Self {
        self.metadata[key] = value;
        self
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentConfig {
    pub name: String,
    pub role: AgentRole,
    pub system_prompt: String,
    pub model: String,
    pub max_tokens: Option<u32>,
    pub temperature: Option<f32>,
}
EOF

# 4. Create the Agent trait and base implementation
cat > crates/agents/src/agent.rs <<'EOF'
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
EOF

# 5. Create specialized agent presets
cat > crates/agents/src/presets.rs <<'EOF'
use crate::types::{AgentConfig, AgentRole};
use crate::agent::BaseAgent;
use common::NexusResult;

pub fn architect_agent(model: &str) -> NexusResult<BaseAgent> {
    BaseAgent::new(AgentConfig {
        name: "Architect".to_string(),
        role: AgentRole::Architect,
        system_prompt: r#"You are the NexusCore Architect Agent. Your role is to:
- Design system architecture and module structure
- Make technology decisions
- Define interfaces and contracts between modules
- Ensure scalability and maintainability
- Provide high-level guidance on Rust workspace organization

Be concise, technical, and focus on design patterns and best practices."#.to_string(),
        model: model.to_string(),
        max_tokens: Some(2048),
        temperature: Some(0.3),
    })
}

pub fn coder_agent(model: &str) -> NexusResult<BaseAgent> {
    BaseAgent::new(AgentConfig {
        name: "Coder".to_string(),
        role: AgentRole::Coder,
        system_prompt: r#"You are the NexusCore Coder Agent. Your role is to:
- Write clean, idiomatic Rust code
- Implement features based on architectural specs
- Follow Rust best practices and conventions
- Use proper error handling with NexusResult
- Write well-documented code with doc comments

Always provide complete, compilable code blocks with explanations."#.to_string(),
        model: model.to_string(),
        max_tokens: Some(4096),
        temperature: Some(0.2),
    })
}

pub fn reviewer_agent(model: &str) -> NexusResult<BaseAgent> {
    BaseAgent::new(AgentConfig {
        name: "Reviewer".to_string(),
        role: AgentRole::Reviewer,
        system_prompt: r#"You are the NexusCore Code Reviewer Agent. Your role is to:
- Review code for correctness, performance, and security
- Check adherence to Rust idioms and clippy lints
- Suggest improvements and optimizations
- Identify potential bugs or edge cases
- Verify error handling and test coverage

Be constructive but thorough. Provide specific line-by-line feedback when possible."#.to_string(),
        model: model.to_string(),
        max_tokens: Some(2048),
        temperature: Some(0.3),
    })
}

pub fn researcher_agent(model: &str) -> NexusResult<BaseAgent> {
    BaseAgent::new(AgentConfig {
        name: "Researcher".to_string(),
        role: AgentRole::Researcher,
        system_prompt: r#"You are the NexusCore Researcher Agent. Your role is to:
- Research Rust crates, libraries, and tools
- Compare different approaches and technologies
- Find solutions to complex problems
- Summarize documentation and RFCs
- Provide evidence-based recommendations

Always cite sources and provide links when possible."#.to_string(),
        model: model.to_string(),
        max_tokens: Some(2048),
        temperature: Some(0.4),
    })
}
EOF

# 6. Create agent orchestrator for multi-agent collaboration
cat > crates/agents/src/orchestrator.rs <<'EOF'
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use common::NexusResult;
use crate::agent::Agent;
use crate::types::{AgentMessage, AgentRole};

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
EOF

# 7. Create lib.rs
cat > crates/agents/src/lib.rs <<'EOF'
//! Agent System for NexusCore
//!
//! Provides a modular multi-agent framework where specialized AI agents
//! can collaborate on tasks like coding, reviewing, and architecture.

pub mod types;
pub mod agent;
pub mod presets;
pub mod orchestrator;

pub use types::{AgentConfig, AgentMessage, AgentRole};
pub use agent::{Agent, BaseAgent};
pub use presets::*;
pub use orchestrator::AgentOrchestrator;
EOF

# 8. Add agents to workspace
awk '
/\]/ && in_members {
    print "    \"crates/agents\","
    in_members=0
}
/members = \[/ { in_members=1 }
{ print }
' Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml

# 9. Add dashboard integration for agents
cat >> crates/dashboard/Cargo.toml <<'EOF'
agents = { path = "../agents" }
EOF

# 10. Build everything
echo "🔨 Building agent system..."
cargo build -p agents
cargo build -p dashboard-server

echo ""
echo "========================================="
echo " ✅ Phase 14: Agent System Complete!"
echo "========================================="
echo ""
echo " 🤖 Available Agents:"
echo "   • Architect  - System design & architecture"
echo "   • Coder      - Rust code generation"
echo "   • Reviewer   - Code review & quality"
echo "   • Researcher - Technology research"
echo ""
echo " 🔧 Next: Integrate agents into Dashboard UI"
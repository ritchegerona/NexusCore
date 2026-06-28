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

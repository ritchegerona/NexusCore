//! Agent System for NexusCore
//!
//! Provides a modular multi-agent framework where specialized AI agents
//! can collaborate on tasks like coding, reviewing, and architecture.

pub mod types;
pub mod agent;
pub mod presets;
pub mod orchestrator;
pub mod intent;

pub use types::{AgentConfig, AgentMessage, AgentRole};
pub use agent::{Agent, BaseAgent};
pub use presets::*;
pub use orchestrator::AgentOrchestrator;
pub use intent::{classify_intent, intent_to_agent, Intent, TaskType};

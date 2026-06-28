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

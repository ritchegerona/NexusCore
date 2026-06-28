use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TaskType {
    Architecture,
    Coding,
    Review,
    Research,
    Debugging,
    Documentation,
    General,
}

impl std::fmt::Display for TaskType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TaskType::Architecture => write!(f, "architecture"),
            TaskType::Coding => write!(f, "coding"),
            TaskType::Review => write!(f, "review"),
            TaskType::Research => write!(f, "research"),
            TaskType::Debugging => write!(f, "debugging"),
            TaskType::Documentation => write!(f, "documentation"),
            TaskType::General => write!(f, "general"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Intent {
    pub task_type: TaskType,
    pub confidence: f32,
    pub keywords: Vec<String>,
}

pub fn classify_intent(input: &str) -> Intent {
    let lower = input.to_lowercase();
    
    // Keyword-based classification with scoring
    let mut scores = vec![
        (TaskType::Architecture, 0.0),
        (TaskType::Coding, 0.0),
        (TaskType::Review, 0.0),
        (TaskType::Research, 0.0),
        (TaskType::Debugging, 0.0),
        (TaskType::Documentation, 0.0),
        (TaskType::General, 0.1), // Base score
    ];

    // Architecture keywords
    if lower.contains("design") || lower.contains("structure") || lower.contains("architecture") 
       || lower.contains("module") || lower.contains("interface") || lower.contains("pattern") {
        scores[0].1 += 0.8;
    }

    // Coding keywords
    if lower.contains("write") || lower.contains("implement") || lower.contains("create") 
       || lower.contains("function") || lower.contains("struct") || lower.contains("code")
       || lower.contains("fn ") || lower.contains("impl ") {
        scores[1].1 += 0.8;
    }

    // Review keywords
    if lower.contains("review") || lower.contains("check") || lower.contains("audit") 
       || lower.contains("optimize") || lower.contains("improve") || lower.contains("best practice") {
        scores[2].1 += 0.8;
    }

    // Research keywords
    if lower.contains("compare") || lower.contains("research") || lower.contains("find") 
       || lower.contains("crate") || lower.contains("library") || lower.contains("alternative") {
        scores[3].1 += 0.8;
    }

    // Debugging keywords
    if lower.contains("error") || lower.contains("bug") || lower.contains("fix") 
       || lower.contains("panic") || lower.contains("compile error") || lower.contains("why doesn't") {
        scores[4].1 += 0.8;
    }

    // Documentation keywords
    if lower.contains("document") || lower.contains("readme") || lower.contains("explain") 
       || lower.contains("how to use") || lower.contains("api doc") {
        scores[5].1 += 0.8;
    }

    // Extract keywords from input
    let keywords: Vec<String> = lower.split_whitespace()
        .filter(|w| w.len() > 3 && !["the", "and", "for", "with", "this", "that"].contains(w))
        .take(5)
        .map(|s| s.to_string())
        .collect();

    // Find highest score
    scores.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    let (task_type, confidence) = scores[0];

    Intent {
        task_type,
        confidence,
        keywords,
    }
}

pub fn intent_to_agent(task_type: &TaskType) -> &'static str {
    match task_type {
        TaskType::Architecture => "architect",
        TaskType::Coding => "coder",
        TaskType::Review => "reviewer",
        TaskType::Research => "researcher",
        TaskType::Debugging => "coder", // Coder handles debugging too
        TaskType::Documentation => "researcher", // Researcher writes docs
        TaskType::General => "general",
    }
}

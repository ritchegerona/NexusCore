#!/usr/bin/env bash
set -e

echo "🧠 Initializing Phase 17: Intelligent Multimodal System..."

# 1. Add Intent Classification Module to Agents Crate
cat > crates/agents/src/intent.rs <<'EOF'
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
EOF

# Update agents lib.rs
sed -i '' 's/pub mod orchestrator;/pub mod orchestrator;\npub mod intent;/' crates/agents/src/lib.rs
sed -i '' 's/pub use orchestrator::AgentOrchestrator;/pub use orchestrator::AgentOrchestrator;\npub use intent::{classify_intent, intent_to_agent, Intent, TaskType};/' crates/agents/src/lib.rs

# 2. Update Dashboard Handlers to Use Auto-Routing
cat >> crates/dashboard/src/handlers.rs <<'EOF'

// --- AUTO-ROUTING ENDPOINT ---
#[derive(Deserialize)]
pub struct AutoRouteRequest {
    pub message: String,
    pub current_agent: Option<String>,
}

#[derive(Serialize)]
pub struct AutoRouteResponse {
    pub selected_agent: String,
    pub task_type: String,
    pub confidence: f32,
    pub explanation: String,
}

pub async fn auto_route(Json(req): Json<AutoRouteRequest>) -> Json<AutoRouteResponse> {
    use agents::{classify_intent, intent_to_agent};
    
    let intent = classify_intent(&req.message);
    let selected_agent = intent_to_agent(&intent.task_type);
    
    // If user explicitly selected an agent, respect it unless confidence is very low
    let final_agent = if let Some(user_agent) = req.current_agent {
        if user_agent != "general" && intent.confidence < 0.4 {
            user_agent
        } else {
            selected_agent.to_string()
        }
    } else {
        selected_agent.to_string()
    };

    let explanation = format!(
        "Detected '{}' task (confidence: {:.0}%). Routed to {} agent.",
        intent.task_type,
        intent.confidence * 100.0,
        final_agent
    );

    Json(AutoRouteResponse {
        selected_agent: final_agent,
        task_type: intent.task_type.to_string(),
        confidence: intent.confidence,
        explanation,
    })
}
EOF

# Register new route in lib.rs
sed -i '' 's|.route("/api/agents/chat", post(handlers::agent_chat))|.route("/api/agents/chat", post(handlers::agent_chat))\n        .route("/api/auto-route", post(handlers::auto_route))|' crates/dashboard/src/lib.rs

# 3. Update Dashboard HTML with Auto-Routing & Multimodal UI
cat > crates/dashboard/static/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexusCore Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <script src="https://cdn.jsdelivr.net/npm/axios@1.6.8/dist/axios.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; }
        #chat-history { overflow-y: auto !important; max-height: calc(100vh - 280px); scrollbar-gutter: stable; }
        .code-block { font-family: 'JetBrains Mono', monospace; background: #0f172a; border-left: 3px solid #3b82f6; white-space: pre-wrap; word-break: break-word; }
        .chat-message pre { background: #0f172a; border-radius: 8px; padding: 1rem; overflow-x: auto; margin: 0.5rem 0; border: 1px solid #1e293b; }
        .chat-message code { font-family: 'JetBrains Mono', monospace; font-size: 0.8rem; color: #e2e8f0; }
        .chat-message p { margin-bottom: 0.75rem; line-height: 1.7; }
        .glass-panel { background: rgba(30, 41, 59, 0.6); backdrop-filter: blur(16px); border: 1px solid rgba(148, 163, 184, 0.08); }
        .agent-btn.active { background: rgba(59, 130, 246, 0.2); border-color: rgba(59, 130, 246, 0.5); }
        .auto-badge { animation: pulse 2s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #475569; border-radius: 3px; }
    </style>
</head>
<body class="bg-slate-950 text-slate-200 h-screen flex flex-col overflow-hidden">
    <!-- Header -->
    <header class="border-b border-slate-800/80 px-6 py-3 flex-shrink-0 bg-slate-950/80 backdrop-blur-md z-20">
        <div class="flex items-center justify-between max-w-[1920px] mx-auto">
            <div class="flex items-center gap-3">
                <img src="/static/assets/logo.png" alt="NexusCore" class="w-9 h-9">
                <div><h1 class="text-lg font-semibold text-white tracking-tight leading-none">NexusCore</h1><p class="text-[10px] text-slate-500 font-medium tracking-[0.2em] uppercase mt-0.5">Agents · Connect · Create</p></div>
            </div>
            <div class="flex items-center gap-3">
                <span id="routing-indicator" class="hidden flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-500/10 text-blue-400 text-[11px] font-medium border border-blue-500/20 auto-badge">
                    <i data-lucide="sparkles" class="w-3 h-3"></i>Auto-Routed
                </span>
                <span class="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-400 text-[11px] font-medium border border-emerald-500/20"><span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>Online</span>
                <span class="text-[11px] text-slate-600 font-mono">v0.1.0</span>
            </div>
        </div>
    </header>

    <!-- Main Layout -->
    <main class="flex-1 flex max-w-[1920px] mx-auto w-full p-4 gap-4 min-h-0 overflow-hidden">
        <!-- Left Panel -->
        <section class="w-[400px] flex-shrink-0 flex flex-col gap-4 overflow-y-auto pr-1">
            <div class="grid grid-cols-3 gap-3">
                <div class="glass-panel rounded-xl p-4 text-center"><p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Crates</p><p class="text-xl font-bold text-white">7</p></div>
                <div class="glass-panel rounded-xl p-4 text-center"><p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Tests</p><p class="text-xl font-bold text-emerald-400">11</p></div>
                <div class="glass-panel rounded-xl p-4 text-center"><p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">
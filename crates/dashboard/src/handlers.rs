use agents::Agent;

use axum::{
    extract::{State, WebSocketUpgrade, ws::{Message, WebSocket}},
    http::StatusCode,
    response::{Html, IntoResponse, Json, Response},
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio_stream::wrappers::ReceiverStream;
use tokio_stream::StreamExt;
use tokio::process::Command;
use tokio::io::AsyncReadExt;
use tokio::sync::mpsc;
use std::process::Stdio;
use futures::{StreamExt as FuturesStreamExt, SinkExt};

#[derive(Debug, Clone)]
pub struct AppState {
    pub workspace_path: String,
}

#[derive(Serialize)]
pub struct DashboardData {
    pub title: String,
    pub version: String,
    pub workspace: String,
    pub crates_count: usize,
    pub status: String,
}

#[derive(Deserialize)]
pub struct ChatRequest {
    pub provider: Option<String>,
    pub model: Option<String>,
    pub message: String,
}

pub async fn root() -> Html<&'static str> {
    Html(include_str!("../static/index.html"))
}

pub async fn api_dashboard(State(_state): State<Arc<Mutex<AppState>>>) -> Json<DashboardData> {
    Json(DashboardData {
        title: "NexusCore Dashboard".to_string(),
        version: "0.1.0".to_string(),
        workspace: "/workspace".to_string(),
        crates_count: 6,
        status: "Running".to_string(),
    })
}

pub async fn api_health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

pub async fn build_workspace() -> Response {
    tokio::spawn(async {
        let _output = Command::new("cargo")
            .args(["build", "--workspace"])
            .output()
            .await;
    });

    Json(serde_json::json!({
        "status": "started",
        "message": "Build process initiated"
    })).into_response()
}

pub async fn run_tests() -> Response {
    tokio::spawn(async {
        let _output = Command::new("cargo")
            .args(["test", "--workspace"])
            .output()
            .await;
    });

    Json(serde_json::json!({
        "status": "started",
        "message": "Test process initiated"
    })).into_response()
}

pub async fn open_docs() -> Response {
    tokio::spawn(async {
        let _ = Command::new("cargo")
            .args(["doc", "--open"])
            .spawn();
    });

    Json(serde_json::json!({
        "status": "started",
        "message": "Documentation opening"
    })).into_response()
}

pub async fn chat(
    State(_state): State<Arc<Mutex<AppState>>>,
    Json(req): Json<ChatRequest>,
) -> Response {
    let provider_str = req.provider.unwrap_or_else(|| "ollama".to_string());
    let model_name = req.model.unwrap_or_else(|| "gemma:2b-instruct".to_string());
    let provider = match provider_str.to_lowercase().as_str() {
        "openai" => llm::ModelProvider::OpenAI,
        "gemini" => llm::ModelProvider::Gemini,
        "deepseek" => llm::ModelProvider::DeepSeek,
        "qwen" => llm::ModelProvider::Qwen,
        _ => llm::ModelProvider::Ollama,
    };
    let client = llm::LlmClient::new(provider, &model_name).unwrap();
    let response = client.ask(&req.message).await;
    
    match response {
        Ok(text) => Json(serde_json::json!({
            "response": text,
            "status": "success"
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Error: {}", e)).into_response(),
    }
}

pub async fn logs_websocket(ws: WebSocketUpgrade) -> Response {
    ws.on_upgrade(move |socket| async move {
        handle_logs(socket).await;
    })
}

async fn handle_logs(socket: WebSocket) {
    let (mut sender, _receiver) = FuturesStreamExt::split(socket);
    
    let (tx, rx) = mpsc::channel::<String>(100);
    
    tokio::spawn(async move {
        let mut cmd = Command::new("cargo")
            .args(["build", "--workspace"])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .expect("Failed to start build process");

        if let Some(stdout) = cmd.stdout.take() {
            let tx_clone = tx.clone();
            tokio::spawn(async move {
                let mut reader = tokio::io::BufReader::new(stdout);
                let mut buffer = [0; 1024];
                
                while let Ok(n) = reader.read(&mut buffer).await {
                    if n == 0 { break; }
                    let log = String::from_utf8_lossy(&buffer[..n]).to_string();
                    let _ = tx_clone.send(log).await;
                }
            });
        }

        if let Some(stderr) = cmd.stderr.take() {
            let tx_clone = tx.clone();
            tokio::spawn(async move {
                let mut reader = tokio::io::BufReader::new(stderr);
                let mut buffer = [0; 1024];
                
                while let Ok(n) = reader.read(&mut buffer).await {
                    if n == 0 { break; }
                    let log = String::from_utf8_lossy(&buffer[..n]).to_string();
                    let _ = tx_clone.send(log).await;
                }
            });
        }

        let _ = cmd.wait().await;
    });

    let mut stream = ReceiverStream::new(rx);
    while let Some(log) = StreamExt::next(&mut stream).await {
        if sender.send(Message::Text(log)).await.is_err() {
            break;
        }
    }
}

// --- AGENT ENDPOINTS ---

#[derive(Deserialize)]
pub struct AgentChatRequest {
    pub agent: String,
    pub message: String,
}

pub async fn list_agents() -> Json<serde_json::Value> {
    let agents = serde_json::json!([
        { "name": "Architect", "role": "System Design & Architecture", "icon": "compass", "color": "blue" },
        { "name": "Coder", "role": "Rust Code Generation", "icon": "code", "color": "emerald" },
        { "name": "Reviewer", "role": "Code Review & Quality", "icon": "search-check", "color": "amber" },
        { "name": "Researcher", "role": "Technology Research", "icon": "book-open", "color": "purple" }
    ]);
    Json(agents)
}

pub async fn agent_chat(Json(req): Json<AgentChatRequest>) -> Response {
    use agents::presets::*;
    
    let provider_str = req.provider.clone().unwrap_or_else(|| "ollama".to_string());
    let model_name = req.model.clone().unwrap_or_else(|| "gemma:2b-instruct".to_string());
    let provider = match provider_str.to_lowercase().as_str() {
        "openai" => llm::ModelProvider::OpenAI,
        "gemini" => llm::ModelProvider::Gemini,
        "deepseek" => llm::ModelProvider::DeepSeek,
        "qwen" => llm::ModelProvider::Qwen,
        _ => llm::ModelProvider::Ollama,
    };
    let agent_result = match req.agent.to_lowercase().as_str() {
        "architect" => architect_agent(&model_name),
        "coder" => coder_agent(&model_name),
        "reviewer" => reviewer_agent(&model_name),
        "researcher" => researcher_agent(&model_name),
        _ => return (StatusCode::BAD_REQUEST, format!("Unknown agent: {}", req.agent)).into_response(),
    };

    match agent_result {
        Ok(agent) => {
            match agent.think(&req.message).await {
                Ok(response) => Json(serde_json::json!({
                    "agent": req.agent,
                    "response": response,
                    "status": "success"
                })).into_response(),
                Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Agent error: {}", e)).into_response(),
            }
        }
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create agent: {}", e)).into_response(),
    }
}

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

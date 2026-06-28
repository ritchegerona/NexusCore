use axum::{
    extract::State,
    http::StatusCode,
    response::{Html, IntoResponse, Json},
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;

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

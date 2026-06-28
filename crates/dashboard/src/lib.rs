pub mod handlers;

use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;
use tokio::sync::Mutex;
use tower_http::services::ServeDir;

pub use handlers::AppState;

pub fn create_router(state: Arc<Mutex<AppState>>) -> Router {
    Router::new()
        .route("/", get(handlers::root))
        .route("/api/dashboard", get(handlers::api_dashboard))
        .route("/api/health", get(handlers::api_health))
        .route("/api/build", get(handlers::build_workspace))
        .route("/api/test", get(handlers::run_tests))
        .route("/api/chat", post(handlers::chat))
        .route("/api/docs", get(handlers::open_docs))
        .route("/api/logs/ws", get(handlers::logs_websocket))
        .route("/api/agents", get(handlers::list_agents))
        .route("/api/agents/chat", post(handlers::agent_chat))
        .route("/api/auto-route", post(handlers::auto_route))
        .nest_service("/static", ServeDir::new("./crates/dashboard/static"))
        .with_state(state)
}

pub async fn run_dashboard(host: &str, port: u16) -> common::NexusResult<()> {
    use std::net::SocketAddr;
    
    let state = Arc::new(Mutex::new(AppState {
        workspace_path: ".".to_string(),
    }));

    let app = create_router(state);
    let addr: SocketAddr = format!("{}:{}", host, port).parse().unwrap();

    tracing::info!("Dashboard starting at http://{}", addr);
    println!("🚀 Dashboard available at: http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();

    Ok(())
}

pub mod handlers;

use axum::{
    routing::get,
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
        .nest_service("/static", ServeDir::new("crates/dashboard/static"))
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

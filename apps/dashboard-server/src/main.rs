use dashboard::{AppState, run_dashboard};
use logger::init_logger;
use std::sync::Arc;
use tokio::sync::Mutex;

#[tokio::main]
async fn main() {
    // Initialize logger
    if let Err(e) = init_logger("info") {
        eprintln!("Failed to initialize logger: {}", e);
        std::process::exit(1);
    }

    tracing::info!("Starting NexusCore Dashboard Server...");

    // Create application state
    let state = Arc::new(Mutex::new(AppState {
        workspace_path: ".".to_string(),
    }));

    // Run dashboard on port 3000
    if let Err(e) = run_dashboard("127.0.0.1", 3000).await {
        tracing::error!("Dashboard failed: {}", e);
        std::process::exit(1);
    }
}

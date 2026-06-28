use dashboard::{AppState, run_dashboard};
use logger::init_logger;
use std::sync::Arc;
use tokio::sync::Mutex;

use dotenv::dotenv;

#[tokio::main]
async fn main() {
    // Load environment variables from .env file
    dotenv().ok();
    
    // Initialize logger
    if let Err(e) = init_logger("info") {
        eprintln!("Failed to initialize logger: {}", e);
        std::process::exit(1);
    }

    tracing::info!("Starting NexusCore Dashboard Server...");
    
    // Verify keys are loaded (optional debug check)
    if std::env::var("OPENAI_API_KEY").is_err() {
        tracing::warn!("OPENAI_API_KEY not set in environment");
    }
    
    // ... rest of your code
}
use async_runtime::{HttpClient, read_file_async, write_file_async};
use common::NexusResult;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct User {
    id: u32,
    name: String,
    email: String,
}

pub async fn run_async_demo() -> NexusResult<()> {
    tracing::info!("Starting async demonstration...");

    // Demo 1: Async file operations
    tracing::info!("Demo 1: Async file operations");
    let test_file = "async_test.txt";
    write_file_async(test_file, "Hello from async Rust!").await?;
    let content = read_file_async(test_file).await?;
    tracing::info!("Async file content: {}", content);

    // Demo 2: HTTP client (using JSONPlaceholder API)
    tracing::info!("Demo 2: HTTP client with JSONPlaceholder API");
    let client = HttpClient::new("https://jsonplaceholder.typicode.com")?;
    
    match client.get::<User>("/users/1").await {
        Ok(user) => {
            tracing::info!("Fetched user: {} ({})", user.name, user.email);
        }
        Err(e) => {
            tracing::warn!("HTTP request failed (expected in offline mode): {}", e);
        }
    }

    // Cleanup
    tokio::fs::remove_file(test_file).await.ok();

    tracing::info!("Async demonstration complete!");
    Ok(())
}

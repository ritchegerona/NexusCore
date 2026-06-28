use common::{NexusResult, NexusError};
use tokio::fs;
use std::path::Path;

pub async fn read_file_async(path: &str) -> NexusResult<String> {
    tracing::debug!("Async reading file: {}", path);
    fs::read_to_string(path)
        .await
        .map_err(|e| NexusError::Filesystem(std::io::Error::other(
            format!("Failed to read '{}': {}", path, e)
        )))
}

pub async fn write_file_async(path: &str, content: &str) -> NexusResult<()> {
    tracing::debug!("Async writing file: {}", path);
    fs::write(path, content)
        .await
        .map_err(|e| NexusError::Filesystem(std::io::Error::other(
            format!("Failed to write '{}': {}", path, e)
        )))
}

pub async fn create_dir_async(path: &str) -> NexusResult<()> {
    tracing::debug!("Async creating directory: {}", path);
    fs::create_dir_all(path)
        .await
        .map_err(|e| NexusError::Filesystem(std::io::Error::other(
            format!("Failed to create directory '{}': {}", path, e)
        )))
}

pub async fn file_exists_async(path: &str) -> bool {
    Path::new(path).exists()
}

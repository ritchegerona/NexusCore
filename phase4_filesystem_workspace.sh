#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 4: Filesystem & Workspace Crates..."

# --- FILESYSTEM CRATE ---
echo "📦 Setting up 'filesystem' crate..."
cat > crates/filesystem/Cargo.toml <<EOF
[package]
name = "filesystem"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
tracing = "0.1"
EOF

cat > crates/filesystem/src/operations.rs <<EOF
use common::{NexusResult, NexusError};
use std::fs;
use std::path::Path;

pub fn read_file(path: &str) -> NexusResult<String> {
    tracing::debug!("Reading file: {}", path);
    fs::read_to_string(path).map_err(|e| {
        NexusError::Filesystem(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            format!("Failed to read '{}': {}", path, e)
        ))
    })
}

pub fn write_file(path: &str, content: &str) -> NexusResult<()> {
    tracing::debug!("Writing file: {}", path);
    fs::write(path, content).map_err(|e| {
        NexusError::Filesystem(std::io::Error::new(
            std::io::ErrorKind::Other,
            format!("Failed to write '{}': {}", path, e)
        ))
    })
}

pub fn create_dir(path: &str) -> NexusResult<()> {
    tracing::debug!("Creating directory: {}", path);
    fs::create_dir_all(path).map_err(|e| {
        NexusError::Filesystem(std::io::Error::new(
            std::io::ErrorKind::Other,
            format!("Failed to create directory '{}': {}", path, e)
        ))
    })
}

pub fn file_exists(path: &str) -> bool {
    Path::new(path).exists()
}
EOF

cat > crates/filesystem/src/lib.rs <<EOF
pub mod operations;

pub use operations::{read_file, write_file, create_dir, file_exists};
EOF

# --- WORKSPACE CRATE ---
echo "📦 Setting up 'workspace' crate..."
cat > crates/workspace/Cargo.toml <<EOF
[package]
name = "workspace"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
filesystem = { path = "../filesystem" }
serde = { version = "1.0", features = ["derive"] }
tracing = "0.1"
EOF

cat > crates/workspace/src/manager.rs <<EOF
use common::{NexusResult, NexusError};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Workspace {
    pub name: String,
    pub path: PathBuf,
    pub created_at: String,
}

impl Workspace {
    pub fn new(name: &str, path: &str) -> NexusResult<Self> {
        let workspace = Self {
            name: name.to_string(),
            path: PathBuf::from(path),
            created_at: chrono::Utc::now().to_rfc3339(),
        };
        
        // Create workspace directory
        filesystem::create_dir(path)?;
        
        tracing::info!("Workspace '{}' created at {:?}", name, path);
        Ok(workspace)
    }
    
    pub fn save(&self, config_path: &str) -> NexusResult<()> {
        let content = serde_json::to_string_pretty(self)
            .map_err(|e| NexusError::Config(format!("Failed to serialize workspace: {}", e)))?;
        
        filesystem::write_file(config_path, &content)?;
        tracing::info!("Workspace config saved to {}", config_path);
        Ok(())
    }
}
EOF

cat > crates/workspace/src/lib.rs <<EOF
pub mod manager;

pub use manager::Workspace;
EOF

# Update workspace Cargo.toml to add chrono dependency
echo "🔧 Updating workspace dependencies..."
cat >> crates/workspace/Cargo.toml <<EOF
chrono = "0.4"
serde_json = "1.0"
EOF

# --- VERIFICATION ---
echo "🔍 Verifying filesystem and workspace crates..."
cargo check -p filesystem
cargo check -p workspace

echo "✅ Phase 4 (Filesystem & Workspace) Complete!"
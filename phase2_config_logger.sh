#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 2 (Part 2): Config & Logger Crates..."

# --- CONFIG CRATE ---
echo "📦 Setting up 'config' crate..."
cat > crates/config/Cargo.toml <<EOF
[package]
name = "config"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
serde = { version = "1.0", features = ["derive"] }
toml = "0.8"
EOF

cat > crates/config/src/settings.rs <<EOF
use serde::Deserialize;

#[derive(Debug, Deserialize, Clone)]
pub struct NexusConfig {
    pub app_name: String,
    pub log_level: String,
    pub max_workers: Option<u32>,
}

impl Default for NexusConfig {
    fn default() -> Self {
        Self {
            app_name: "NexusCore".to_string(),
            log_level: "info".to_string(),
            max_workers: Some(4),
        }
    }
}
EOF

cat > crates/config/src/lib.rs <<EOF
pub mod settings;

use common::NexusResult;
use crate::settings::NexusConfig;
use std::fs;

pub fn load_config(path: &str) -> NexusResult<NexusConfig> {
    let content = fs::read_to_string(path)
        .map_err(|e| common::NexusError::Config(format!("Failed to read '{}': {}", path, e)))?;
    
    let config: NexusConfig = toml::from_str(&content)
        .map_err(|e| common::NexusError::Config(format!("Failed to parse TOML: {}", e)))?;
        
    Ok(config)
}
EOF

# --- LOGGER CRATE ---
echo "📦 Setting up 'logger' crate..."
cat > crates/logger/Cargo.toml <<EOF
[package]
name = "logger"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
EOF

cat > crates/logger/src/lib.rs <<EOF
use common::{NexusResult, NexusError};
use tracing_subscriber::{fmt, EnvFilter};

pub fn init_logger(log_level: &str) -> NexusResult<()> {
    let filter = EnvFilter::try_new(log_level)
        .map_err(|e| NexusError::Config(format!("Invalid log level '{}': {}", log_level, e)))?;

    fmt()
        .with_env_filter(filter)
        .with_target(false)
        .init();

    tracing::info!("Logger initialized successfully.");
    Ok(())
}
EOF

# --- VERIFICATION ---
echo "🔍 Verifying config and logger crates..."
cargo check -p config
cargo check -p logger

echo "✅ Phase 2 (Config & Logger) Complete!"
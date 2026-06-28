#!/usr/bin/env bash
set -e

echo "🔧 Creating missing LLM crate..."

# 1. Create 'llm' crate
echo "📦 Creating 'llm' crate..."
mkdir -p crates/llm/src
cd crates/llm
cargo init --lib --vcs none > /dev/null
cd ../..

# 2. Update llm Cargo.toml
cat > crates/llm/Cargo.toml <<'EOF'
[package]
name = "llm"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
reqwest = { version = "0.11", features = ["json"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.35", features = ["full"] }
tracing = "0.1"
EOF

# 3. Create Ollama client
cat > crates/llm/src/client.rs <<'EOF'
use common::{NexusResult, NexusError};
use reqwest::Client;
use serde::{Deserialize, Serialize};

const OLLAMA_BASE_URL: &str = "http://localhost:11434";

#[derive(Debug, Serialize)]
struct GenerateRequest {
    model: String,
    prompt: String,
    stream: bool,
}

#[derive(Debug, Deserialize)]
struct GenerateResponse {
    response: String,
}

pub struct OllamaClient {
    client: Client,
    model: String,
}

impl OllamaClient {
    pub fn new(model: &str) -> NexusResult<Self> {
        let client = Client::builder()
            .build()
            .map_err(|e| NexusError::Config(format!("Failed to create HTTP client: {}", e)))?;

        Ok(Self {
            client,
            model: model.to_string(),
        })
    }

    pub async fn ask(&self, prompt: &str) -> NexusResult<String> {
        let url = format!("{}/api/generate", OLLAMA_BASE_URL);
        tracing::debug!("Sending prompt to Ollama: {}", self.model);

        let request = GenerateRequest {
            model: self.model.clone(),
            prompt: prompt.to_string(),
            stream: false,
        };

        let response = self.client
            .post(&url)
            .json(&request)
            .send()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to connect to Ollama: {}", e)))?;

        if !response.status().is_success() {
            return Err(NexusError::Config(format!("Ollama API error: {}", response.status())));
        }

        let result: GenerateResponse = response
            .json()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to parse response: {}", e)))?;

        Ok(result.response)
    }
}
EOF

cat > crates/llm/src/lib.rs <<'EOF'
//! LLM integration for NexusCore using Ollama

pub mod client;
pub use client::OllamaClient;
EOF

# 4. Add llm to workspace
echo "🔗 Adding 'llm' to workspace..."
awk '
/\]/ && in_members {
    print "    \"crates/llm\","
    in_members=0
}
/members = \[/ { in_members=1 }
{ print }
' Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml

# 5. Update dashboard Cargo.toml to include llm
cat > crates/dashboard/Cargo.toml <<'EOF'
[package]
name = "dashboard"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
config = { path = "../config" }
logger = { path = "../logger" }
workspace = { path = "../workspace" }
llm = { path = "../llm" }
axum = "0.7"
tokio = { version = "1.35", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tracing = "0.1"
tower = "0.4"
tower-http = { version = "0.5", features = ["fs", "cors"] }
chrono = "0.4"
EOF

echo "✅ LLM crate created!"
echo ""
echo "🔨 Now building dashboard server..."
cargo build -p dashboard-server

echo ""
echo "========================================="
echo " ✅ Ready to run!"
echo "========================================="
echo "Run with: cargo run -p dashboard-server"
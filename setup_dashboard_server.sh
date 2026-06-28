#!/usr/bin/env bash
set -e

echo "🚀 Setting up Dashboard Server..."

# 1. Create dashboard-server binary app
echo "📦 Creating 'apps/dashboard-server' binary..."
mkdir -p apps/dashboard-server/src
cd apps/dashboard-server
cargo init --bin --vcs none > /dev/null
cd ../..

# 2. Update dashboard-server Cargo.toml
cat > apps/dashboard-server/Cargo.toml <<'EOF'
[package]
name = "dashboard-server"
version.workspace = true
edition.workspace = true

[dependencies]
dashboard = { path = "../../crates/dashboard" }
common = { path = "../../crates/common" }
logger = { path = "../../crates/logger" }
tokio = { version = "1.35", features = ["full"] }
tracing = "0.1"
EOF

# 3. Create main.rs for dashboard server
cat > apps/dashboard-server/src/main.rs <<'EOF'
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
EOF

# 4. Add dashboard-server to workspace
echo "🔗 Adding 'dashboard-server' to workspace..."
awk '
/\]/ && in_members {
    print "    \"apps/dashboard-server\","
    in_members=0
}
/members = \[/ { in_members=1 }
{ print }
' Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml

# 5. Build the dashboard server
echo "🔨 Building dashboard server..."
cargo build -p dashboard-server

echo ""
echo "========================================="
echo " ✅ Dashboard Server Ready!"
echo "========================================="
echo ""
echo " 🚀 Run the dashboard:"
echo "    cargo run -p dashboard-server"
echo ""
echo " 🌐 Then open your browser:"
echo "    http://localhost:3000"
echo ""
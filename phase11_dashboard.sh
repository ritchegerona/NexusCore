#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 11: Web Dashboard..."

# 1. Create 'dashboard' crate
echo "📦 Creating 'dashboard' web server crate..."
mkdir -p crates/dashboard/src
cd crates/dashboard
cargo init --lib --vcs none > /dev/null
cd ../..

# 2. Update dashboard Cargo.toml
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
EOF

# 3. Create web handlers
cat > crates/dashboard/src/handlers.rs <<'EOF'
use axum::{
    extract::State,
    http::StatusCode,
    response::{Html, IntoResponse, Json},
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;

#[derive(Debug, Clone)]
pub struct AppState {
    pub workspace_path: String,
}

#[derive(Serialize)]
pub struct DashboardData {
    pub title: String,
    pub version: String,
    pub workspace: String,
    pub crates_count: usize,
    pub status: String,
}

#[derive(Deserialize)]
pub struct ChatRequest {
    pub message: String,
}

pub async fn root() -> Html<&'static str> {
    Html(include_str!("../static/index.html"))
}

pub async fn api_dashboard(State(_state): State<Arc<Mutex<AppState>>>) -> Json<DashboardData> {
    Json(DashboardData {
        title: "NexusCore Dashboard".to_string(),
        version: "0.1.0".to_string(),
        workspace: "/workspace".to_string(),
        crates_count: 6,
        status: "Running".to_string(),
    })
}

pub async fn api_health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}
EOF

# 4. Create HTML template
mkdir -p crates/dashboard/static
cat > crates/dashboard/static/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexusCore Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
</head>
<body class="bg-gray-900 text-white min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <header class="mb-8">
            <h1 class="text-4xl font-bold text-blue-400">🚀 NexusCore Dashboard</h1>
            <p class="text-gray-400 mt-2">Modular Rust Workspace Framework</p>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-400 text-sm">Status</p>
                        <p class="text-2xl font-bold text-green-400">Running</p>
                    </div>
                    <i data-lucide="activity" class="w-8 h-8 text-green-400"></i>
                </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-400 text-sm">Crates</p>
                        <p class="text-2xl font-bold text-blue-400">6</p>
                    </div>
                    <i data-lucide="package" class="w-8 h-8 text-blue-400"></i>
                </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-gray-400 text-sm">Version</p>
                        <p class="text-2xl font-bold text-purple-400">0.1.0</p>
                    </div>
                    <i data-lucide="tag" class="w-8 h-8 text-purple-400"></i>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700">
                <h2 class="text-xl font-bold mb-4">Quick Actions</h2>
                <div class="space-y-2">
                    <button class="w-full bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded text-left">
                        📦 Build Workspace
                    </button>
                    <button class="w-full bg-green-600 hover:bg-green-700 px-4 py-2 rounded text-left">
                        🧪 Run Tests
                    </button>
                    <button class="w-full bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded text-left">
                        📊 View Documentation
                    </button>
                </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-6 border border-gray-700">
                <h2 class="text-xl font-bold mb-4">System Info</h2>
                <div class="space-y-2 text-sm">
                    <div class="flex justify-between">
                        <span class="text-gray-400">Rust Edition:</span>
                        <span>2021</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">Workspace:</span>
                        <span>Active</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-gray-400">Async Runtime:</span>
                        <span>Tokio</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        lucide.createIcons();
    </script>
</body>
</html>
EOF

# 5. Create lib.rs
cat > crates/dashboard/src/lib.rs <<'EOF'
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
EOF

# 6. Add dashboard to workspace
echo "🔗 Adding 'dashboard' to workspace..."
awk '
/\]/ && in_members {
    print "    \"crates/dashboard\","
    in_members=0
}
/members = \[/ { in_members=1 }
{ print }
' Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml

# 7. Add dashboard command to nexus-cli
cat >> apps/nexus-cli/src/main.rs <<'EOF'

// Add to Commands enum:
// Dashboard,

// Add to match:
// Some(Commands::Dashboard) => {
//     let rt = tokio::runtime::Runtime::new().unwrap();
//     rt.block_on(async {
//         if let Err(e) = dashboard::run_dashboard("127.0.0.1", 3000).await {
//             tracing::error!("Dashboard failed: {}", e);
//             std::process::exit(1);
//         }
//     });
// }
EOF

echo "✅ Phase 11 (Dashboard) setup complete!"
echo "Run with: cargo run -p dashboard"
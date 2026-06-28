#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 10: Async Support & HTTP Client..."

# 1. Create new async crate
echo "📦 Creating 'async-runtime' crate..."
mkdir -p crates/async-runtime/src
cd crates/async-runtime
cargo init --lib --vcs none > /dev/null
cd ../..

# 2. Update async-runtime Cargo.toml
cat > crates/async-runtime/Cargo.toml <<'EOF'
[package]
name = "async-runtime"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../common" }
tokio = { version = "1.35", features = ["full"] }
reqwest = { version = "0.11", features = ["json"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tracing = "0.1"
EOF

# 3. Create async HTTP client module
cat > crates/async-runtime/src/http_client.rs <<'EOF'
use common::{NexusResult, NexusError};
use reqwest::Client;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub message: Option<String>,
}

pub struct HttpClient {
    client: Client,
    base_url: String,
}

impl HttpClient {
    pub fn new(base_url: &str) -> NexusResult<Self> {
        let client = Client::builder()
            .build()
            .map_err(|e| NexusError::Config(format!("Failed to create HTTP client: {}", e)))?;

        Ok(Self {
            client,
            base_url: base_url.to_string(),
        })
    }

    pub async fn get<T: for<'de> Deserialize<'de>>(&self, endpoint: &str) -> NexusResult<T> {
        let url = format!("{}{}", self.base_url, endpoint);
        tracing::debug!("GET request to: {}", url);

        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| NexusError::Config(format!("HTTP GET failed: {}", e)))?;

        if !response.status().is_success() {
            return Err(NexusError::Config(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let data = response
            .json::<T>()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to parse JSON: {}", e)))?;

        Ok(data)
    }

    pub async fn post<T: Serialize, R: for<'de> Deserialize<'de>>(
        &self,
        endpoint: &str,
        body: &T,
    ) -> NexusResult<R> {
        let url = format!("{}{}", self.base_url, endpoint);
        tracing::debug!("POST request to: {}", url);

        let response = self.client
            .post(&url)
            .json(body)
            .send()
            .await
            .map_err(|e| NexusError::Config(format!("HTTP POST failed: {}", e)))?;

        if !response.status().is_success() {
            return Err(NexusError::Config(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let data = response
            .json::<R>()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to parse JSON: {}", e)))?;

        Ok(data)
    }
}
EOF

# 4. Create async file operations module
cat > crates/async-runtime/src/async_fs.rs <<'EOF'
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
EOF

# 5. Update async-runtime lib.rs
cat > crates/async-runtime/src/lib.rs <<'EOF'
//! Async runtime and utilities for NexusCore
//!
//! This crate provides asynchronous operations using Tokio runtime
//! and HTTP client capabilities using Reqwest.

pub mod http_client;
pub mod async_fs;

pub use http_client::{HttpClient, ApiResponse};
pub use async_fs::{read_file_async, write_file_async, create_dir_async, file_exists_async};
EOF

# 6. Add async-runtime to workspace
echo "🔗 Adding 'async-runtime' to workspace..."
awk '
/\]/ && in_members {
    print "    \"crates/async-runtime\","
    in_members=0
}
/members = \[/ { in_members=1 }
{ print }
' Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml

# 7. Create async demo in nexus-cli
cat > apps/nexus-cli/src/async_demo.rs <<'EOF'
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
EOF

# 8. Update nexus-cli main.rs to include async demo
cat > apps/nexus-cli/src/main.rs <<'EOF'
use clap::{Parser, Subcommand};
use logger::init_logger;
use workspace::Workspace;
use dialoguer::{theme::ColorfulTheme, Select, Input};
use console::style;

mod async_demo;

#[derive(Parser)]
#[command(name = "nexus-cli")]
#[command(about = "NexusCore CLI - A modular Rust workspace framework", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize a new workspace
    Init {
        #[arg(short, long)]
        name: Option<String>,
        #[arg(short, long, default_value = ".")]
        path: String,
    },
    Build {
        #[arg(short, long)]
        release: bool,
    },
    Test {
        #[arg(short, long)]
        verbose: bool,
    },
    Info,
    Interactive,
    /// Run async demonstration
    AsyncDemo,
}

fn main() {
    if let Err(e) = init_logger("info") {
        eprintln!("Failed to initialize logger: {}", e);
        std::process::exit(1);
    }

    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Init { name, path }) => handle_init(name, path),
        Some(Commands::Build { release }) => handle_build(release),
        Some(Commands::Test { verbose }) => handle_test(verbose),
        Some(Commands::Info) => handle_info(),
        Some(Commands::Interactive) => handle_interactive(),
        Some(Commands::AsyncDemo) => {
            let rt = tokio::runtime::Runtime::new().unwrap();
            rt.block_on(async {
                if let Err(e) = async_demo::run_async_demo().await {
                    tracing::error!("Async demo failed: {}", e);
                    std::process::exit(1);
                }
            });
        }
        None => {
            tracing::info!("Welcome to NexusCore CLI!");
            println!("Run {} for usage information.", style("nexus-cli --help").cyan());
        }
    }
}

fn handle_init(name: Option<String>, path: String) {
    let workspace_name = name.unwrap_or_else(|| {
        Input::with_theme(&ColorfulTheme::default())
            .with_prompt("Workspace name")
            .default("my-workspace".into())
            .interact_text()
            .unwrap()
    });

    tracing::info!("Initializing workspace '{}' at '{}'...", workspace_name, path);
    
    match Workspace::new(&workspace_name, &path) {
        Ok(ws) => {
            let config_path = format!("{}/workspace.json", path);
            if let Err(e) = ws.save(&config_path) {
                tracing::error!("Failed to save workspace config: {}", e);
                std::process::exit(1);
            }
            
            println!("{}", style("✓ Workspace created successfully!").green());
            println!("  Name: {}", ws.name);
            println!("  Path: {}", ws.path.display());
        }
        Err(e) => {
            tracing::error!("Failed to create workspace: {}", e);
            std::process::exit(1);
        }
    }
}

fn handle_build(release: bool) {
    let mode = if release { "release" } else { "debug" };
    tracing::info!("Building workspace in {} mode...", mode);
    
    let status = if release {
        std::process::Command::new("cargo")
            .args(["build", "--release", "--workspace"])
            .status()
    } else {
        std::process::Command::new("cargo")
            .args(["build", "--workspace"])
            .status()
    };

    match status {
        Ok(s) if s.success() => {
            println!("{}", style("✓ Build completed successfully!").green());
        }
        Ok(s) => {
            tracing::error!("Build failed with status: {}", s);
            std::process::exit(1);
        }
        Err(e) => {
            tracing::error!("Failed to execute build: {}", e);
            std::process::exit(1);
        }
    }
}

fn handle_test(verbose: bool) {
    tracing::info!("Running tests...");
    
    let mut cmd = std::process::Command::new("cargo");
    cmd.args(["test", "--workspace"]);
    
    if verbose {
        cmd.arg("--verbose");
    }

    match cmd.status() {
        Ok(s) if s.success() => {
            println!("{}", style("✓ All tests passed!").green());
        }
        Ok(s) => {
            tracing::error!("Tests failed with status: {}", s);
            std::process::exit(1);
        }
        Err(e) => {
            tracing::error!("Failed to execute tests: {}", e);
            std::process::exit(1);
        }
    }
}

fn handle_info() {
    println!("{}", style("NexusCore Workspace Information").cyan().bold());
    println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    
    match config::load_config("nexus.toml") {
        Ok(cfg) => {
            println!("Application: {}", cfg.app_name);
            println!("Log Level:   {}", cfg.log_level);
            println!("Max Workers: {:?}", cfg.max_workers.unwrap_or(4));
        }
        Err(_) => {
            println!("Configuration: Not found (using defaults)");
        }
    }
    
    println!("\nCrates:");
    println!("  • common        - Shared types and utilities");
    println!("  • config        - Configuration management");
    println!("  • logger        - Structured logging");
    println!("  • filesystem    - File operations");
    println!("  • workspace     - Workspace management");
    println!("  • async-runtime - Async operations & HTTP client");
}

fn handle_interactive() {
    println!("{}", style("NexusCore Interactive Mode").cyan().bold());
    println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    
    let options = vec![
        "Initialize workspace",
        "Build project",
        "Run tests",
        "Show info",
        "Run async demo",
        "Exit"
    ];
    
    let selection = Select::with_theme(&ColorfulTheme::default())
        .with_prompt("What would you like to do?")
        .items(&options)
        .default(0)
        .interact()
        .unwrap();

    match selection {
        0 => handle_init(None, ".".to_string()),
        1 => handle_build(false),
        2 => handle_test(false),
        3 => handle_info(),
        4 => {
            let rt = tokio::runtime::Runtime::new().unwrap();
            rt.block_on(async {
                if let Err(e) = async_demo::run_async_demo().await {
                    tracing::error!("Async demo failed: {}", e);
                }
            });
        }
        5 => {
            println!("{}", style("Goodbye!").green());
            std::process::exit(0);
        }
        _ => unreachable!(),
    }
}
EOF

# 9. Update nexus-cli Cargo.toml
cat > apps/nexus-cli/Cargo.toml <<'EOF'
[package]
name = "nexus-cli"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../../crates/common" }
config = { path = "../../crates/config" }
logger = { path = "../../crates/logger" }
filesystem = { path = "../../crates/filesystem" }
workspace = { path = "../../crates/workspace" }
async-runtime = { path = "../../crates/async-runtime" }
tracing = "0.1"
clap = { version = "4.4", features = ["derive"] }
dialoguer = "0.11"
console = "0.15"
tokio = { version = "1.35", features = ["full"] }
EOF

# 10. Build and test
echo "🏃 Building async features..."
cargo build -p async-runtime
cargo build -p nexus-cli

echo ""
echo "========================================="
echo " ✅ Phase 10 Complete!"
echo "========================================="
echo " Async runtime and HTTP client added!"
echo ""
echo " 📋 New command available:"
echo "   nexus-cli async-demo"
echo ""
echo " Try it now:"
echo "   cargo run -p nexus-cli -- async-demo"
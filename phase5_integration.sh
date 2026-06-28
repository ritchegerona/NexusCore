#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 5: Full Integration & Demo..."

# 1. Update nexus-cli dependencies to include filesystem and workspace
echo "🔧 Updating nexus-cli dependencies..."
cat > apps/nexus-cli/Cargo.toml <<EOF
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
tracing = "0.1"
EOF

# 2. Update main.rs to demonstrate full integration
cat > apps/nexus-cli/src/main.rs <<EOF
use config::settings::NexusConfig;
use logger::init_logger;
use workspace::Workspace;

fn main() {
    // 1. Initialize Logger
    let default_level = "info";
    if let Err(e) = init_logger(default_level) {
        eprintln!("Failed to initialize logger: {}", e);
        std::process::exit(1);
    }

    tracing::info!("Starting NexusCore CLI...");

    // 2. Load Configuration
    let config_path = "nexus.toml";
    let app_config = match config::load_config(config_path) {
        Ok(cfg) => {
            tracing::info!("Loaded configuration from {}", config_path);
            cfg
        }
        Err(_) => {
            tracing::warn!("Configuration file '{}' not found. Using defaults.", config_path);
            NexusConfig::default()
        }
    };

    tracing::info!("Application Name: {}", app_config.app_name);
    tracing::info!("Max Workers: {:?}", app_config.max_workers);

    // 3. Create a demo workspace
    tracing::info!("Creating demo workspace...");
    match Workspace::new("demo-workspace", "./demo-workspace") {
        Ok(ws) => {
            tracing::info!("Workspace '{}' created successfully!", ws.name);
            
            // Save workspace config
            if let Err(e) = ws.save("./demo-workspace/workspace.json") {
                tracing::error!("Failed to save workspace config: {}", e);
            }
            
            // Test filesystem operations
            let test_file = "./demo-workspace/test.txt";
            if let Err(e) = filesystem::write_file(test_file, "Hello from NexusCore!") {
                tracing::error!("Failed to write test file: {}", e);
            } else {
                tracing::info!("Test file created at {}", test_file);
                
                // Read it back
                match filesystem::read_file(test_file) {
                    Ok(content) => tracing::info!("File content: {}", content),
                    Err(e) => tracing::error!("Failed to read file: {}", e),
                }
            }
        }
        Err(e) => {
            tracing::error!("Failed to create workspace: {}", e);
            std::process::exit(1);
        }
    }
    
    println!("\n✅ NexusCore is fully operational!");
    println!("📁 Demo workspace created at: ./demo-workspace");
    println!("📄 Check the files inside to see the integration working!");
}
EOF

# 3. Run the application
echo "🏃 Running integrated NexusCore CLI..."
cargo run -p nexus-cli

echo ""
echo "========================================="
echo " ✅ Phase 5 Complete!"
echo "========================================="
echo " All crates are now fully integrated."
echo " Check ./demo-workspace/ for the output."
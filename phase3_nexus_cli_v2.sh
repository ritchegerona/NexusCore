#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 3: Nexus CLI (Binary App)..."

# 1. Linisin at gumawa ng directory
echo "📦 Creating 'apps/nexus-cli' binary..."
rm -rf apps/nexus-cli
mkdir -p apps/nexus-cli/src

# 2. Initialize Cargo project sa loob ng folder
cd apps/nexus-cli
cargo init --bin --vcs none > /dev/null
cd ../..

# 3. Update apps/nexus-cli/Cargo.toml with dependencies
cat > apps/nexus-cli/Cargo.toml <<EOF
[package]
name = "nexus-cli"
version.workspace = true
edition.workspace = true

[dependencies]
common = { path = "../../crates/common" }
config = { path = "../../crates/config" }
logger = { path = "../../crates/logger" }
tracing = "0.1"
EOF

# 4. Write the main.rs logic
cat > apps/nexus-cli/src/main.rs <<EOF
use config::settings::NexusConfig;
use logger::init_logger;

fn main() {
    // 1. Initialize Logger with default level
    let default_level = "info";
    if let Err(e) = init_logger(default_level) {
        eprintln!("Failed to initialize logger: {}", e);
        std::process::exit(1);
    }

    tracing::info!("Starting NexusCore CLI...");

    // 2. Load Configuration (fallback to default if file not found)
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
    
    println!("🚀 NexusCore is ready!");
}
EOF

# 5. Create a sample configuration file in the root
cat > nexus.toml <<EOF
app_name = "NexusCore Production"
log_level = "debug"
max_workers = 8
EOF

# 6. Add apps/nexus-cli to the workspace members in root Cargo.toml
echo "🔗 Adding 'apps/nexus-cli' to workspace members..."
awk '
/\]/ && in_members {
    print "    \"apps/nexus-cli\","
    in_members=0
}
/members = \[/ { in_members=1 }
{ print }
' Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml

# 7. Run the application to verify everything works together
echo "🏃 Running 'cargo run -p nexus-cli'..."
cargo run -p nexus-cli

echo "✅ Phase 3 Complete! The NexusCore workspace is fully integrated."
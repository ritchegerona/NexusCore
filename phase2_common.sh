#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 2: Common Crate Foundation..."

# 1. I-update ang dependencies ng common crate
cat > crates/common/Cargo.toml <<EOF
[package]
name = "common"
version.workspace = true
edition.workspace = true

[dependencies]
thiserror = "1.0"
serde = { version = "1.0", features = ["derive"] }
EOF

# 2. Gumawa ng error.rs (Unified Error Types)
cat > crates/common/src/error.rs <<EOF
use thiserror::Error;

#[derive(Error, Debug)]
pub enum NexusError {
    #[error("Configuration error: {0}")]
    Config(String),

    #[error("Filesystem error: {0}")]
    Filesystem(#[from] std::io::Error),

    #[error("Unknown error: {0}")]
    Unknown(String),
}
EOF

# 3. Gumawa ng result.rs (Custom Result Alias)
cat > crates/common/src/result.rs <<EOF
use crate::error::NexusError;

pub type NexusResult<T> = std::result::Result<T, NexusError>;
EOF

# 4. I-update ang lib.rs para ma-export ang mga modules
cat > crates/common/src/lib.rs <<EOF
pub mod error;
pub mod result;

pub use error::NexusError;
pub use result::NexusResult;
EOF

# 5. I-verify kung nag-compile nang tama
echo "🔍 Verifying common crate..."
cargo check -p common

echo "✅ Phase 2 (Common Crate) Complete!"
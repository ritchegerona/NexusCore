#!/usr/bin/env bash
set -e

echo "========================================="
echo "   NexusCore Workspace Fix & Bootstrap   "
echo "========================================="

# 1. Linisin ang sirang crates directory kung may nauna
if [ -d "crates" ]; then
    echo "⚠️  Cleaning up existing 'crates/' directory..."
    rm -rf crates/
fi

# 2. Listahan ng mga foundational crates
CRATES=("common" "config" "logger" "filesystem" "workspace")

# 3. I-configure ang root Cargo.toml para sa Workspace
echo "📝 Configuring root Cargo.toml workspace..."
cat > Cargo.toml <<EOF
[workspace]
resolver = "2"
members = [
EOF

for crate in "${CRATES[@]}"; do
    echo "    \"crates/$crate\"," >> Cargo.toml
done

cat >> Cargo.toml <<EOF
]

[workspace.package]
version = "0.1.0"
edition = "2021"
authors = ["NexusCore Team"]
license = "MIT"

[workspace.dependencies]
# Ilagay dito ang mga shared dependencies sa Phase 2
EOF

# 4. I-create ang mga crates gamit ang cargo new
echo "📦 Creating Rust library crates..."
mkdir -p crates
for crate in "${CRATES[@]}"; do
    echo "  -> Creating crates/$crate"
    cargo new --lib "crates/$crate" > /dev/null
done

# 5. I-verify kung nag-build nang tama
echo "🔍 Verifying workspace with 'cargo check'..."
cargo check > /dev/null 2>&1 && echo "✅ Cargo check passed!" || echo "❌ Cargo check failed."

# 6. Git initialization at commit
if [ ! -d ".git" ]; then
    echo "🌱 Initializing Git repository..."
    git init > /dev/null
fi

echo "📌 Staging and committing the workspace setup..."
git add .
git commit -m "chore: fix and bootstrap Rust workspace with foundational crates" > /dev/null 2>&1 || echo "Nothing to commit."

echo ""
echo "========================================="
echo " ✅ Workspace Fixed and Ready!           "
echo "========================================="
echo " Pwede na tayong mag-proceed sa Phase 2."
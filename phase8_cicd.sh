#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 8: Code Quality & CI/CD Setup..."

# 1. Create rustfmt configuration
echo "📝 Creating rustfmt.toml..."
cat > rustfmt.toml <<EOF
edition = "2021"
max_width = 100
tab_spaces = 4
use_field_init_shorthand = true
use_try_shorthand = true
EOF

# 2. Create clippy configuration
echo "📝 Creating clippy.toml..."
cat > clippy.toml <<EOF
cognitive-complexity-threshold = 30
too-many-arguments-threshold = 8
type-complexity-threshold = 250
EOF

# 3. Create GitHub Actions workflow
echo "🔧 Creating GitHub Actions workflow..."
mkdir -p .github/workflows

cat > .github/workflows/ci.yml <<EOF
name: CI

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master, develop ]

env:
  CARGO_TERM_COLOR: always

jobs:
  test:
    name: Test Suite
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Install Rust toolchain
      uses: dtolnay/rust-toolchain@stable
      with:
        components: rustfmt, clippy
    
    - name: Cache cargo registry
      uses: actions/cache@v3
      with:
        path: |
          ~/.cargo/registry
          ~/.cargo/git
          target
        key: \${{ runner.os }}-cargo-\${{ hashFiles('**/Cargo.lock') }}
    
    - name: Check formatting
      run: cargo fmt --all -- --check
    
    - name: Run clippy
      run: cargo clippy --workspace --all-targets --all-features -- -D warnings
    
    - name: Run tests
      run: cargo test --workspace --verbose
    
    - name: Build release
      run: cargo build --release --workspace

  security-audit:
    name: Security Audit
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Install cargo-audit
      run: cargo install cargo-audit
    
    - name: Run security audit
      run: cargo audit
EOF

# 4. Create pre-commit hook script
echo "🪝 Creating pre-commit hook..."
cat > scripts/pre-commit.sh <<EOF
#!/usr/bin/env bash
set -e

echo "🔍 Running pre-commit checks..."

# Check formatting
echo "📝 Checking code formatting..."
cargo fmt --all -- --check || {
    echo "❌ Code formatting issues found. Run 'cargo fmt --all' to fix."
    exit 1
}

# Run clippy
echo "🔬 Running clippy..."
cargo clippy --workspace --all-targets -- -D warnings || {
    echo "❌ Clippy warnings found. Please fix them."
    exit 1
}

# Run tests
echo "🧪 Running tests..."
cargo test --workspace || {
    echo "❌ Tests failed. Please fix them before committing."
    exit 1
}

echo "✅ All pre-commit checks passed!"
EOF

chmod +x scripts/pre-commit.sh

# 5. Create Makefile for common tasks
echo "🛠️ Creating Makefile..."
cat > Makefile <<EOF
.PHONY: build test fmt clippy clean doc run

# Build all crates
build:
	cargo build --workspace

# Build release version
release:
	cargo build --release --workspace

# Run all tests
test:
	cargo test --workspace

# Format code
fmt:
	cargo fmt --all

# Check formatting
fmt-check:
	cargo fmt --all -- --check

# Run clippy lints
clippy:
	cargo clippy --workspace --all-targets -- -D warnings

# Clean build artifacts
clean:
	cargo clean

# Generate documentation
doc:
	cargo doc --workspace --no-deps --open

# Run the CLI
run:
	cargo run -p nexus-cli

# Run pre-commit checks
pre-commit:
	./scripts/pre-commit.sh

# Run all quality checks
check: fmt-check clippy test

# Install development tools
setup:
	rustup component add rustfmt clippy
	cargo install cargo-audit
EOF

# 6. Create .gitignore additions
echo "📝 Updating .gitignore..."
cat >> .gitignore <<EOF

# Build artifacts
/target/
**/*.rs.bk

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Demo/test artifacts
/demo-workspace/
test_*.txt
test_*.toml
test_dir/
test_workspace/
test_ws_save/
EOF

# 7. Run code quality checks
echo "🔍 Running code quality checks..."
cargo fmt --all
cargo clippy --workspace --all-targets -- -D warnings

echo ""
echo "========================================="
echo " ✅ Phase 8 Complete!"
echo "========================================="
echo " NexusCore is now production-ready!"
echo ""
echo " 📋 Available commands:"
echo "   make build      - Build all crates"
echo "   make test       - Run all tests"
echo "   make fmt        - Format code"
echo "   make clippy     - Run linter"
echo "   make check      - Run all quality checks"
echo "   make doc        - Generate documentation"
echo "   make run        - Run the CLI"
echo ""
echo " 🔧 CI/CD pipeline configured in .github/workflows/ci.yml"
echo " 🪝 Pre-commit hook available at scripts/pre-commit.sh"
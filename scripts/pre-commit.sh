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

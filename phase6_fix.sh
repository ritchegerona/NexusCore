#!/usr/bin/env bash
set -e

echo "🔧 Fixing workspace tests..."

# Add the missing import to the test module
sed -i '' '/mod tests {/a\
    use filesystem::file_exists;
' crates/workspace/src/manager.rs

echo "🏃 Running all tests again..."
cargo test --workspace

echo ""
echo "✅ Tests should now pass!"
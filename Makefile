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

# NexusCore

A modular Rust workspace framework for building scalable, production-ready applications with clean architecture and async-first design.

## Features

- **Modular Architecture** — Workspace-based crate organization with clear separation of concerns
- **Async-First** — Built on Tokio for high-performance non-blocking operations
- **Unified Error Handling** — Custom `NexusError` and `NexusResult<T>` types for consistent error propagation
- **Type-Safe Configuration** — TOML-based config with Serde validation
- **Structured Logging** — Tracing-based observability with context-aware logs
- **LLM Integration** — Built-in support for language model operations
- **Agent Framework** — Extensible agent system for autonomous tasks
- **Dashboard Server** — Web-based monitoring and control interface
- **CLI Tool** — Command-line interface for workspace management

## Quick Start

### Prerequisites

- Rust 1.70+ and Cargo
- macOS or Linux
- SQLite3 (for data persistence)
- Ollama (optional, for local LLM)

### Build

```bash
cargo build --workspace
```

### Run CLI

```bash
cargo run --bin nexus-cli
```

### Run Dashboard

```bash
cargo run --bin dashboard-server
```

## Project Structure

```
NexusCore/
├── crates/              # Core library crates
│   ├── common/          # Shared types, errors, utilities
│   ├── config/          # Configuration management
│   ├── logger/          # Structured logging
│   ├── filesystem/      # File operations
│   ├── workspace/       # Workspace management
│   ├── async-runtime/   # Tokio runtime utilities
│   ├── llm/             # LLM integration
│   ├── agents/          # Agent framework
│   └── dashboard/       # Dashboard backend
├── apps/                # Application binaries
│   ├── nexus-cli/       # CLI application
│   └── dashboard-server/ # Web dashboard
├── docs/                # Documentation
├── bootstrap/           # Setup scripts
└── scripts/             # Utility scripts
```

## Architecture

NexusCore follows a modular design with these principles:

1. **Single Responsibility** — Each crate has a specific, well-defined purpose
2. **Loose Coupling** — Crates communicate through well-defined interfaces
3. **High Cohesion** — Related functionality is grouped together
4. **Error Propagation** — Unified error types across the workspace
5. **Async by Default** — Non-blocking I/O for all operations

## Development

### Run Tests

```bash
cargo test --workspace
```

### Check Code

```bash
cargo clippy --workspace
cargo fmt --check
```

### Build Documentation

```bash
cargo doc --open --workspace
```

## Configuration

Create a `nexus.toml` file in your project root:

```toml
[app]
name = "MyApp"
version = "0.1.0"

[logging]
level = "info"
format = "json"

[database]
path = "./data/app.db"
```

## Roadmap

- [ ] Complete agent framework implementation
- [ ] Add plugin system for extensibility
- [ ] Implement distributed task queue
- [ ] Add WebSocket support for real-time dashboard
- [ ] Create comprehensive test suite
- [ ] Add CI/CD pipeline templates

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Built by [Ritche Gerona](https://github.com/ritchegerona)

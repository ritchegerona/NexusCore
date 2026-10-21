# Contributing to NexusCore

Thanks for your interest in improving NexusCore! This document explains how to
set up the project, make changes, and submit them.

## Prerequisites

- **Rust 1.70+** (stable) and Cargo
- `rustfmt` and `clippy` components (`make setup` installs them)
- macOS or Linux

## Getting started

```bash
git clone https://github.com/ritchegerona/NexusCore.git
cd NexusCore
make build          # cargo build --workspace
```

## Development workflow

1. **Fork** the repository and create a topic branch off the default branch:

   ```bash
   git checkout -b feat/short-description
   ```

2. Make your change. Keep commits focused and messages in the imperative mood
   (e.g. `feat(llm): add retry on rate limit`).

3. Run the full quality gate before pushing:

   ```bash
   make check        # fmt-check + clippy + test
   ```

   Individually:

   ```bash
   make fmt          # cargo fmt --all
   make clippy       # cargo clippy --workspace --all-targets -- -D warnings
   make test         # cargo test --workspace
   ```

   `clippy` is configured to treat warnings as errors, and CI enforces this.

4. Open a **pull request** against the default branch with a clear description
   of the problem and the solution. Reference any related issues.

## Coding standards

- Follow Rust 2021 idioms; run `cargo fmt` so formatting is never a review topic.
- Each crate has a single, well-defined responsibility. Prefer adding a focused
  crate or module over growing an unrelated one.
- Use the workspace error types (`NexusError` / `NexusResult<T>`) instead of
  ad-hoc error handling.
- Add tests for new behavior. `cargo test --workspace` must stay green.
- Keep public APIs documented with `///` doc comments.

## Commit & PR checklist

- [ ] Branch is up to date with the default branch
- [ ] `make check` passes locally
- [ ] New/changed behavior is covered by tests
- [ ] Docs (`README.md`, `docs/`) updated when relevant
- [ ] PR description explains the *why*, not just the *what*

## Reporting bugs & requesting features

Open a GitHub issue using the available templates. Include your OS, Rust
version (`rustc --version`), and clear reproduction steps.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).

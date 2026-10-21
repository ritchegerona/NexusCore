# Security Policy

## Supported Versions

NexusCore is under active development. Security fixes are applied to the latest
release on the default branch.

| Version | Supported |
| ------- | --------- |
| 0.1.x   | ✅        |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, report them privately using GitHub's
[**Report a vulnerability**](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
feature on the **Security** tab of this repository.

Please include, where possible:

- A description of the vulnerability and its impact
- Steps to reproduce (proof of concept if available)
- The affected version/commit and your environment
- Any suggested remediation

## What to expect

- **Acknowledgement** within 3 business days.
- An assessment and, where applicable, a coordinated fix and disclosure
  timeline.
- Credit in the advisory, if you wish.

## Scope notes

- NexusCore integrates with external services (e.g. Ollama / LLM endpoints).
  Configure credentials via environment variables or `nexus.toml`; never commit
  secrets. `.env` is gitignored — keep it that way.
- Run the dashboard server behind authentication when exposed beyond
  `localhost`.

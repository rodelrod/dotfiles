# Project Setup Preferences for AI Coding Agents

Use this as a generic baseline for new projects that should be easy for AI coding agents and humans to understand, modify, test, and operate.

## Core Defaults

- Use Nix flakes for every project environment.
- Commit both `flake.nix` and `flake.lock`.
- Use `direnv` with `.envrc` and `use flake`.
- Put required runtime and developer tools in the Nix dev shell.
- Prefer pinned project-local tooling over global dependencies.
- Make a fresh clone usable with a short documented setup sequence.
- Include a concise root `AGENTS.md` for repo-specific agent instructions.

## Language Tooling

- Python: use `uv`, `pyproject.toml`, `uv.lock`, and documented `uv run ...` commands.
- Node.js: use `npm` and `package-lock.json` unless there is a clear reason to standardize on another package manager.
- Shell: use Bash for orchestration scripts when shell is the simplest interface.
- JavaScript, TypeScript, Python, or other languages: put non-trivial logic in real files under `scripts/`, not long inline shell snippets.
- Pin language runtimes through the Nix flake and, where applicable, project metadata.

## Command Surface

Expose common work through stable, discoverable commands.

- Document setup, test, lint, format, build, run, and clean commands in `README.md`.
- Put canonical commands in `package.json`, `pyproject.toml`, `justfile`, `Makefile`, or another obvious entrypoint.
- Include one fast verification command that can run from a fresh clone.
- Prefer commands like `npm test`, `npm run lint`, `uv run pytest`, or `just test` over ad hoc command chains.
- Keep command names descriptive enough that agents can infer intent before reading implementation.

## Agent Instructions

`AGENTS.md` should be short, concrete, and operational. Include only rules that materially affect work in the repo:

- canonical setup and verification commands
- script invocation conventions
- generated files or directories agents should not edit manually
- destructive actions that require explicit user approval
- project-specific style, architecture, or safety constraints not enforced by tooling

## Scripts and Safety

- Put reusable automation in `scripts/`.
- Use `set -euo pipefail` for Bash scripts.
- Provide `--help` for important scripts.
- Make arguments and environment overrides explicit.
- Move parsing, validation, structured data handling, and complex branching into a general-purpose language.
- Use deterministic ordering for filesystem traversal and generated output.
- Add `--dry-run` to scripts that plan or write changes.
- Make overwrite behavior opt-in with an explicit flag such as `--overwrite`.
- Write outputs to predictable directories and avoid modifying valuable user data by default.

## Configuration

- Use structured config files such as JSON, TOML, YAML, or language-native config.
- Validate config shape before performing work.
- Keep policy decisions, naming rules, paths, and feature flags out of incidental script logic.
- Document environment variables and local overrides.
- Keep secrets and private machine-specific values out of committed files.

## Tests and Validation

- Include small tests with synthetic fixtures when production data is unavailable or private.
- Make tests and validation commands fast enough for agents to run frequently.
- Validate important generated artifacts, not only source code.
- Emit clear pass/fail output and useful diagnostics.
- Treat logs, reports, counts, and manifests as first-class outputs for batch workflows.

## Documentation

- Keep `README.md` operational: what the project is, how to set it up, how to run it, how to test it, and where outputs go.
- Keep long design notes, plans, and historical context separate from the README.
- Prefer concrete commands, paths, flags, and examples over narrative explanation.
- Update docs whenever setup, commands, outputs, or operating rules change.

## Git Hygiene

- Ignore dependency folders, local environments, build outputs, logs, editor backups, and platform files.
- Commit lockfiles.
- Do not commit private data, generated run artifacts, or machine-specific outputs.
- Provide sample config files when local config is required.

## New Project Checklist

- `flake.nix` and `flake.lock`
- `.envrc` with `use flake`
- `.gitignore`
- `README.md`
- `AGENTS.md`
- language package metadata and lockfile
- `scripts/` for reusable automation
- one fast verification command
- structured config for project policies
- dry-run and explicit overwrite behavior for scripts that write files

## Default Agent Behavior

Agents should read the setup docs first, use canonical commands, edit reusable source files instead of terminal-only snippets, run the narrowest relevant verification command after changes, and preserve reproducibility, idempotence, and safety gates.

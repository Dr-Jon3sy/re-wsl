# Repository Instructions

## Purpose

This repository is a native WSL2 reverse-engineering environment. It is a WSL/`uv` fork of [schlarpc/re-shell](https://github.com/schlarpc/re-shell/) and intentionally does not use Nix.

Work from a Linux checkout under `/home` (for example, `~/re-wsl`), not a copy under `/mnt/c`, because virtual environments, `node_modules`, Ghidra projects, and decompilation workloads are much faster on WSL's native filesystem.

## Entering the Environment

Before invoking project tools, run one of:

```sh
source scripts/env.sh
# or
bash scripts/enter.sh
```

For a first-time or dependency setup, run `bash scripts/setup-wsl.sh`. Use `bash scripts/setup-wsl.sh --full` only when the larger optional toolset is needed.

## Reverse-Engineering Work

- Treat every sample, archive, installer, firmware image, capture, and extracted script as untrusted.
- Do not execute a sample or enable its active content unless the user explicitly requests that action and the isolation boundary is understood.
- Put input samples in `inputs/`.
- Put disposable output, extracted trees, decompiled sources, and Ghidra projects in `tmp/`.
- Put durable user-requested reports, rules, hooks, and patches in `artifacts/<identifier>/`.
- Do not put analysis output in the repository root.
- Prefer static inspection before dynamic execution. Record hashes and relevant tool versions in final analysis artifacts.

The detailed general-purpose tool catalog and workflows live in `CLAUDE.md`. Despite that legacy filename, its environment and tool instructions apply equally to Codex. Domain-specific Codex skills are available under `.agents/skills/`:

- `.agents/skills/android/SKILL.md`
- `.agents/skills/windows/SKILL.md`
- `.agents/skills/web/SKILL.md`

Use the matching skill whenever the input or task falls within its description.

## Changing the Toolset

- Python dependencies: use `uv add <package>` and commit both `pyproject.toml` and `uv.lock`.
- Node.js dependencies: use `npm install <package>` and commit both `package.json` and `package-lock.json`.
- Ubuntu packages: update `scripts/setup-wsl.sh` and keep setup idempotent.
- Standalone tools: add a versioned installer under `scripts/` and install into the gitignored `.tools/` directory.
- Keep equivalent skill content synchronized under both `.agents/skills/` and `.claude/skills/`.
- Do not add Nix setup files or make Nix a prerequisite.

## Verification

For configuration changes, run the relevant checks:

```sh
bash -n scripts/*.sh
uv lock --check
npm audit
bash scripts/doctor.sh
```

If setup behavior changed, also run the narrowest safe idempotency check that covers it. Do not claim a tool works merely because it is listed; verify its command or import when practical.

## Repository Hygiene

Commit only source, documentation, lockfiles, and configuration. Never commit analyzed samples, executables, downloaded archives, Ghidra distributions, virtual environments, `node_modules`, generated decompilations, or other binary/runtime artifacts. Keep committed files non-executable unless an executable bit is explicitly required by the repository owner.

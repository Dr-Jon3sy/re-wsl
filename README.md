# re-shell

> [!NOTE]
> This project is a WSL-focused fork of [schlarpc/re-shell](https://github.com/schlarpc/re-shell/), created by Chaz Schlarp. The original project provides the reverse-engineering environment and discipline documentation; this fork replaces its Nix-based setup with native Ubuntu packages, `uv`, npm, and WSL-specific tooling.
> I just don't use nix and don't want to learn :)

A native WSL2 reverse-engineering environment designed for use with [OpenAI Codex](https://developers.openai.com/codex/) and [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It uses Ubuntu packages for system tools, `uv` for a locked Python 3.13 environment, npm for Node.js dependencies, and an official Ghidra release installed inside the project. Nix is not required.

## Quick start

Prerequisites: Ubuntu on WSL2, `uv`, and [Codex](https://learn.chatgpt.com/docs/windows/wsl) or Claude Code installed inside WSL.

Run once:

```sh
git clone git@github.com:Dr-Jon3sy/re-wsl.git ~/re-wsl
cd ~/re-wsl
bash scripts/setup-wsl.sh
source scripts/env.sh
codex
```

Next time:

```sh
cd ~/re-wsl && source scripts/env.sh && codex
```

Use `claude` instead of `codex` if preferred. Put samples in `inputs/`; use `bash scripts/setup-wsl.sh --full` only when you need the larger optional toolset.

Codex reads `AGENTS.md` and `.agents/skills/`. Claude Code reads the equivalent `CLAUDE.md` and `.claude/skills/` files.

## How it works

The environment combines Ghidra, radare2, Frida, mitmproxy, YARA, Android tools, network tools, Python libraries, and more. Codex and Claude Code are configured with discipline-specific **skills** that activate based on file type and context:

| Skill | Activates on | Example files |
|-------|-------------|---------------|
| Windows RE | PE binaries, .NET assemblies, drivers | `.exe`, `.dll`, `.sys` |
| Android RE | Android packages, DEX bytecode | `.apk`, `.xapk` |
| Web RE | HTTP captures, API traffic, protobufs | `.har`, `.proto` |

When an agent detects relevant context, the matching skill loads specialized tool documentation and workflows -- no manual configuration needed.

## Adding tools

The environment is self-modifying. If an analysis needs a tool that isn't installed, the agent can add it:

- **Python packages:** `uv add <pkg>` (the active `.venv` updates automatically)
- **Node.js packages:** `npm install <pkg>`
- **Ubuntu packages:** add the package to `scripts/setup-wsl.sh`, then rerun the script
- **Standalone tools:** add a versioned installer under `scripts/` and install into `.tools/`

If you use `direnv`, the included `.envrc` sources `scripts/env.sh`; `direnv` itself is optional.

## Output directories

- **`tmp/`** -- Intermediate work products (gitignored)
- **`artifacts/`** -- Final deliverables like reports and analysis notes (gitignored)

## WSL notes

- Keep the checkout on WSL's native Linux filesystem. `/mnt/c` is substantially slower for virtual environments, `node_modules`, Ghidra, and large decompilations.
- WSLg is sufficient for the Ghidra GUI on current Windows installations. `analyzeHeadless` works without a GUI.
- USB access from WSL requires attaching the device to WSL (commonly with `usbipd-win`) before Linux tools can see it.
- Packet capture and raw USB/I2C access may still require `sudo` or device-specific udev/group permissions.

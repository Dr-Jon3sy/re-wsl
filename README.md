# re-shell

Set up a reverse-engineering environment on Ubuntu under Windows Subsystem for Linux 2 (WSL2). The environment includes Ghidra, radare2, Frida, mitmproxy, YARA, Android tools, network tools, and Python libraries. It uses `uv` and `npm` instead of Nix.

The environment works best with the OpenAI Codex command-line interface (CLI). Claude Code is also supported.

## Prerequisites

You need the following software and access:

- Ubuntu on WSL2
- Git with Secure Shell (SSH) access to GitHub
- `npm`
- `uv`
- A WSL user with `sudo` access

Keep the repository under your Linux home directory, such as `~/re-wsl`. Paths under `/mnt/c` are slower for virtual environments, `node_modules`, Ghidra projects, and decompilation output.

## Set up the environment

If Ghidra is installed outside the standard locations, set `GHIDRA_INSTALL_DIR` or `GHIDRA_PATH` before you run the setup script. Either variable can point to the Ghidra installation directory or its `ghidraRun` executable. The setup script also checks `PATH`, `.tools/ghidra/current`, `/opt/ghidra`, and `/usr/share/ghidra`.

1. Clone the repository:

   ```sh
   git clone git@github.com:Dr-Jon3sy/re-wsl.git ~/re-wsl
   ```

2. Go to the repository:

   ```sh
   cd ~/re-wsl
   ```

3. Install the toolset:

   ```sh
   bash scripts/setup-wsl.sh
   ```

   The setup script installs the Ubuntu packages, creates the locked Python 3.13 environment, installs the `npm` dependencies, and runs the environment checks. If it finds Ghidra, it uses that installation. Otherwise, it downloads Ghidra to `.tools/`. A successful setup ends with `Environment checks passed.`

4. Configure your current shell:

   ```sh
   source scripts/env.sh
   ```

If you need the password-cracking, field-programmable gate array (FPGA), Arm, Wine, and `scrcpy` packages, run `bash scripts/setup-wsl.sh --full` instead.

## Start a work session

1. Go to the repository:

   ```sh
   cd ~/re-wsl
   ```

2. Configure your shell:

   ```sh
   source scripts/env.sh
   ```

If you use `direnv`, the included `.envrc` configures the shell when you enter the repository.

Put files for analysis in `inputs/`. The agent loads the matching guidance for Windows binaries, Android packages, or web protocols.

## Use the discipline guides

The following guides describe the tools and workflows for each type of analysis:

| Guide | Use for | Example files |
|---|---|---|
| Windows reverse engineering | Portable Executable (PE) binaries, .NET assemblies, and drivers | `.exe`, `.dll`, `.sys` |
| Android reverse engineering | Android packages, Dalvik Executable (DEX) bytecode, and smali | `.apk`, `.xapk` |
| Web reverse engineering | Hypertext Transfer Protocol (HTTP) captures, application programming interfaces (APIs), WebSockets, and Protocol Buffers | `.har`, `.proto` |

Codex loads the guides from `.agents/skills/`. Claude Code loads the equivalent guides from `.claude/skills/`.

## Add tools

To keep a tool in the environment, update the matching dependency source:

- Add a Python package with `uv add PACKAGE`. Commit `pyproject.toml` and `uv.lock`.
- Add a Node.js package with `npm install PACKAGE`. Commit `package.json` and `package-lock.json`.
- Add an Ubuntu package to `scripts/setup-wsl.sh`.
- Add a versioned installer for a standalone tool under `scripts/`, and install the tool under `.tools/`.

After you change the toolset, run `bash scripts/doctor.sh` to verify the environment.

## Store analysis output

Store generated files in the following directories:

- `tmp/`: Intermediate files, extracted content, decompiled sources, and Ghidra projects.
- `artifacts/`: Reports, rules, hooks, patches, and other requested deliverables.

Both directories are excluded from Git.

## Understand the WSL limitations

- WSLg can run the Ghidra graphical interface. `analyzeHeadless` does not require a graphical interface.
- Before Linux tools can access a Universal Serial Bus (USB) device, attach the device to WSL. You can use `usbipd-win` for this task.
- To capture packets or access some USB and Inter-Integrated Circuit (I2C) devices, use `sudo` or configure the required device permissions.

## Project origin

This project is a WSL-focused fork of [Chaz Schlarp's `schlarpc/re-shell`](https://github.com/schlarpc/re-shell/). The original project provides the reverse-engineering environment and discipline documentation. This fork replaces the Nix setup with Ubuntu packages, `uv`, `npm`, and WSL-specific scripts.

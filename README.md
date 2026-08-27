# re-wsl

Set up a reverse-engineering environment on Ubuntu under Windows Subsystem for Linux 2 (WSL2). This project is a WSL-focused fork of [Chaz Schlarp's `schlarpc/re-shell`](https://github.com/schlarpc/re-shell/). It replaces the upstream Nix environment with Ubuntu packages, `uv`, `npm`, and WSL-specific scripts.

The environment works best with the OpenAI Codex command-line interface (CLI). Claude Code can use the mirrored skill files.

## Prerequisites

You need:

- Ubuntu on WSL2
- Git
- Node.js 18 or newer with `npm`
- `uv`
- A WSL user with `sudo` access

The setup script installs Ubuntu's `nodejs` and `npm` packages if they are missing. A Node.js 18 or newer installation managed by `nvm` or `fnm` also works.

Keep the repository under your Linux home directory, such as `~/re-wsl`. Paths under `/mnt/c` are slower for virtual environments, `node_modules`, Ghidra projects, and decompilation output.

## Set up the environment

Clone over HTTPS and run the setup:

```sh
git clone https://github.com/Dr-Jon3sy/re-wsl.git ~/re-wsl
cd ~/re-wsl
bash scripts/setup-wsl.sh
```

If you prefer Secure Shell (SSH), use `git@github.com:Dr-Jon3sy/re-wsl.git` as the clone URL.

The setup script installs the Ubuntu packages, creates the locked Python environment, installs the locked `npm` dependencies, and runs the environment checks. It installs the pinned Ghidra 12.1.3 release with its published SHA-256 checksum and uses OpenJDK 21.

If Ghidra is installed, set `GHIDRA_INSTALL_DIR` or `GHIDRA_PATH` before setup. Either variable can point to the Ghidra installation directory or its `ghidraRun` file. Setup also searches `PATH`, `.tools/ghidra/current`, `/opt/ghidra`, and `/usr/share/ghidra`. The installation must provide `ghidraRun` and `analyzeHeadless`; Ghidra 12 or newer is required by PyGhidra 3.

To install the optional cracking, field-programmable gate array (FPGA), Arm, Wine, and `scrcpy` packages, use:

```sh
bash scripts/setup-wsl.sh --full
```

On amd64 WSL, `--full` enables the i386 package architecture and installs both 64-bit and 32-bit Wine. Hashcat uses the compute devices visible inside WSL; GPU acceleration requires compatible Windows drivers and WSL GPU passthrough.

## Enter the environment

Configure the current Bash session:

```sh
source scripts/env.sh
```

You can also start a clean configured Bash subshell:

```sh
bash scripts/enter.sh
```

If you use `direnv`, the included `.envrc` is the preferred automatic entry method.

## Installed tools

The base setup provides:

| Area | Tools |
|---|---|
| General analysis | Ghidra 12.1.3, radare2, binwalk, YARA, UPX, ripgrep, GNU binutils, ExifTool |
| Android | ADB, Fastboot, Apktool, `aapt`, `apksigner`, `apk-mitm` |
| Windows formats | cabextract, innoextract, msitools, osslsigncode |
| Web and network | mitmproxy, tshark, nmap, HTTPie, Protocol Buffers compiler |
| Python | Frida tools, PyGhidra, Capstone, LIEF, pefile, dnfile, oletools, Unicorn, grpcio, haralyzer, PyUSB, and the locked libraries in `pyproject.toml` |

The `--full` setup adds Hashcat, John the Ripper, Yosys, the GNU Arm Embedded compiler, `scrcpy`, and Wine on amd64. Ubuntu packages use the versions supplied by the selected Ubuntu release; they do not reproduce the upstream Nix version set.

The environment does not package rizin, jadx, dex2jar, Bytecode Viewer, APKiD, APKEditor, Detect It Easy, PE-bear, FLOSS, ILSpy, Volatility, grpcurl, grpcui, curl-impersonate, websocat, pup, Pico SDK, picotool, Project Trellis, HAL, or wordlists. Install one of these tools for a specific task before using its commands.

The Python and Node project metadata retain the upstream internal package name `re-env`. The environment variable `RE_SHELL_ROOT` retains its upstream name for compatibility.

## Use the discipline guides

Codex loads the discipline guides from `.agents/skills/`. Claude Code loads byte-identical copies from `.claude/skills/`. The guides cover only installed tools and label optional tools explicitly.

After changing a guide, verify that both trees match:

```sh
bash scripts/check-skill-sync.sh
```

## Verify the environment

Run the base checks:

```sh
bash scripts/doctor.sh
```

If you installed the optional toolset, include its checks:

```sh
bash scripts/doctor.sh --full
```

A missing required tool is marked `[miss]` and makes the check fail. Missing optional agent CLIs are marked `[info]`.

## Store analysis output

Use:

- `inputs/` for untrusted samples.
- `tmp/` for intermediate files, extracted content, decompiled sources, and Ghidra projects.
- `artifacts/` for reports, rules, hooks, patches, and other requested deliverables.

These directories are excluded from Git. Common sample extensions are also ignored to reduce the chance of committing a binary outside `inputs/`.

## Understand the WSL limitations

- WSLg can run the Ghidra graphical interface. `analyzeHeadless` does not require a graphical interface.
- Before Linux tools can access a Universal Serial Bus (USB) device, attach the device to WSL. You can use `usbipd-win` for this task.
- To capture packets or access some USB and Inter-Integrated Circuit (I2C) devices, use `sudo` or configure the required device permissions.

## Add tools

To keep a tool in the environment:

- Add a Python package with `uv add PACKAGE`, then commit `pyproject.toml` and `uv.lock`.
- Add a Node.js package with `npm install PACKAGE`, then commit `package.json` and `package-lock.json`.
- Add an Ubuntu package to `scripts/setup-wsl.sh`.
- Add a versioned installer under `scripts/` for a standalone tool, and install it under `.tools/`.

Update the tool catalog, both skill trees, the doctor checks, and continuous integration (CI) when the advertised environment changes.

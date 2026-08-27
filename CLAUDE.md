# re-wsl reverse-engineering environment

These instructions describe the WSL toolset used by both Codex and Claude Code. This repository is a WSL and `uv` port of [`schlarpc/re-shell`](https://github.com/schlarpc/re-shell/); it does not use Nix.

## Enter the environment

Before using project tools, run:

```sh
source scripts/env.sh
```

Use `bash scripts/setup-wsl.sh` for the base toolset. Use `bash scripts/setup-wsl.sh --full` only when the optional cracking, FPGA, Arm, Wine, and `scrcpy` packages are needed.

Run `bash scripts/doctor.sh` before relying on the environment. A command is available only if setup installs it or the doctor finds it. Do not substitute tools from the upstream Nix catalog without installing them first.

## Handle samples safely

- Treat binaries, archives, installers, firmware, packet captures, and extracted scripts as untrusted.
- Prefer static inspection before dynamic execution.
- Do not execute a sample or enable active content unless the user explicitly requests it and the isolation boundary is understood.
- Put source samples in `inputs/`.
- Put extracted files, Ghidra projects, and other disposable output in `tmp/`.
- Put reports, YARA rules, hooks, and other requested deliverables in `artifacts/<identifier>/`.
- Record sample hashes and relevant tool versions in durable analysis reports.

## Use the installed tools

The base setup installs the following command-line tools.

| Area | Commands |
|---|---|
| Triage | `file`, `sha256sum`, `strings`, `xxd`, `readelf`, `objdump`, `exiftool` |
| Native analysis | `r2`, `binwalk`, `yara`, `upx`, `ghidraRun`, `analyzeHeadless` |
| Android | `adb`, `fastboot`, `apktool`, `aapt`, `apksigner`, `apk-mitm` |
| Windows formats | `cabextract`, `innoextract`, `msiextract`, `msiinfo`, `osslsigncode` |
| Network and web | `tshark`, `nmap`, `http`, `protoc`, `mitmproxy`, `mitmdump`, `mitmweb` |
| Dynamic instrumentation | `frida`, `frida-ps`, `frida-trace` |
| Data and archives | `jq`, `sqlite3`, `openssl`, `7z`, `unzip` |
| Hardware support | `lsusb`, `i2cdetect`, `ddcutil`, `edid-decode`, `v4l2-ctl` |

The hardware commands are installed, but stock WSL2 does not expose every required kernel interface. See "Understand the WSL limitations" in `README.md` before attempting live I2C or HID access. `edid-decode` can inspect saved EDID files without hardware access.

The `--full` setup adds `hashcat`, `john`, `yosys`, `arm-none-eabi-gcc`, and `scrcpy`. On amd64 WSL it also installs `wine` and `winetricks` with i386 support. GPU acceleration for Hashcat depends on compatible Windows drivers and WSL GPU passthrough.

Ubuntu packages use distribution versions rather than the versions from the upstream Nix lock.

## Use the Python environment

The locked Python environment includes:

- General analysis: Capstone, cryptography, Frida, NumPy, Pillow, PyGhidra, PyUSB, SciPy, and YARA Python.
- Android: hermes-dec and pyaxmlparser.
- Windows: dnfile, LIEF, oletools, pefile, and Unicorn.
- Web: Beautiful Soup, grpcio, grpcio-tools, haralyzer, and protobuf.

Run scripts through the configured environment:

```sh
uv run --frozen python path/to/script.py
```

The setup pins PyGhidra 3.0.2 and Ghidra 12.1.3. PyGhidra 3 requires Ghidra 12 or newer. Open a program from an imported Ghidra project with the PyGhidra 3 project API:

```sh
analyzeHeadless tmp/ghidra sample -import inputs/sample.exe
```

```python
from pathlib import Path

import pyghidra

pyghidra.start()
project = pyghidra.open_project(Path("tmp/ghidra"), "sample")
try:
    with pyghidra.program_context(project, "/sample.exe") as program:
        print(program.getName())
finally:
    project.close()
```

Do not use the deprecated `pyghidra.open_program()` helper in future scripts.

## Start with static triage

Create a working directory and record the sample identity:

```sh
mkdir -p tmp/sample
sha256sum inputs/sample.exe
file inputs/sample.exe
exiftool inputs/sample.exe
strings -a -n 6 inputs/sample.exe | head -n 200
```

Use radare2 for command-line native-code inspection:

```sh
r2 -AA inputs/sample.exe
```

Use Ghidra headlessly when decompilation or cross-reference analysis is needed:

```sh
analyzeHeadless tmp/ghidra sample -import inputs/sample.exe
```

Scan firmware or composite files with Binwalk:

```sh
binwalk inputs/firmware.bin
```

Extract only into `tmp/`, then treat every extracted file as untrusted.

## Inspect USB devices

`scripts/env.sh` resolves `LIBUSB1_SO` without assuming an x86-64 host. Confirm the device is attached to WSL before using PyUSB:

```python
import os

import usb.backend.libusb1
import usb.core

backend = usb.backend.libusb1.get_backend(
    find_library=lambda _: os.environ["LIBUSB1_SO"]
)
for device in usb.core.find(find_all=True, backend=backend):
    print(f"{device.idVendor:04x}:{device.idProduct:04x}")
```

## Do not assume unbundled tools exist

The repository does not package the following upstream tools:

- General and hardware: rizin, asar, hid-tools, picotool, Pico SDK, Project Trellis, and HAL.
- Android: jadx, dex2jar, Bytecode Viewer, APKiD, APKEditor, bundletool, aapt2, jnitrace, trueseeing, quark-engine, koodousfinder, simg2img, sdat2img, payload-dumper-go, and imgpatchtools.
- Windows: PE-bear, Detect It Easy, ImHex, FLOSS, ILSpy, and Volatility.
- Web: protoscope, grpcurl, grpcui, curl-impersonate, websocat, and pup.
- Data: `wordlists/rockyou.txt` and other password dictionaries.

Install an unbundled tool for the specific task before using its command. Do not present its output as part of the standard `re-wsl` environment.

## Keep agent guidance synchronized

Domain-specific guidance is stored in both `.agents/skills/` and `.claude/skills/`. The copies must remain byte-identical. After changing either tree, run:

```sh
bash scripts/check-skill-sync.sh
```

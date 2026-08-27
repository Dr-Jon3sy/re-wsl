---
name: windows
description: Analyze Windows PE files, .NET assemblies, drivers, installers, and signatures with the tools installed by re-wsl.
user-invocable: false
---

# Windows reverse engineering

Use this skill for Portable Executable (PE) files, Dynamic-Link Libraries (DLLs), drivers, .NET assemblies, Cabinet archives, Microsoft Installer packages, and Inno Setup installers.

## Confirm the environment

Before analysis, run:

```sh
source scripts/env.sh
bash scripts/doctor.sh
```

The base environment provides Ghidra, radare2, GNU binutils, YARA, ExifTool, cabextract, innoextract, msitools, osslsigncode, pefile, dnfile, LIEF, oletools, Capstone, and Unicorn.

Wine and Winetricks are available only after `bash scripts/setup-wsl.sh --full` on amd64 WSL. That setup enables i386 support for 32-bit programs.

The environment does not package PE-bear, Detect It Easy (`diec`), ImHex, FLOSS, ILSpy, or Volatility. Install one of those tools before using its command.

## Triage the sample

Create a sample-specific working directory and record the original hash:

```sh
mkdir -p tmp/sample
sha256sum inputs/sample.exe
file inputs/sample.exe
exiftool inputs/sample.exe
objdump -x inputs/sample.exe
strings -a -n 6 inputs/sample.exe | head -n 200
```

Inspect the Authenticode signature without executing the file:

```sh
osslsigncode verify -in inputs/sample.exe
```

Use YARA rules only from a trusted source, and record the ruleset revision in the report:

```sh
yara -r path/to/rules.yar inputs/sample.exe
```

## Inspect native code

Use radare2 for command-line analysis:

```sh
r2 -AA inputs/sample.exe
```

Use Ghidra for decompilation and cross-references:

```sh
analyzeHeadless tmp/ghidra sample -import inputs/sample.exe
```

Keep Ghidra projects under `tmp/`.

## Inspect PE structure with Python

Use pefile for headers, sections, imports, exports, and resources:

```python
import pefile

pe = pefile.PE("inputs/sample.exe", fast_load=False)
print(hex(pe.OPTIONAL_HEADER.ImageBase))
for section in pe.sections:
    print(section.Name.rstrip(b"\\0"), hex(section.VirtualAddress), section.SizeOfRawData)
```

Use dnfile for .NET metadata and LIEF when a script needs cross-format parsing or rewriting. Do not save modified binaries outside `tmp/` unless the user explicitly requests an artifact.

## Extract installers without executing them

Extract supported containers into separate directories:

```sh
cabextract -d tmp/sample/cab inputs/sample.cab
innoextract --output-dir tmp/sample/inno inputs/setup.exe
msiextract -C tmp/sample/msi inputs/setup.msi
```

Treat every extracted file as untrusted. Re-run `file`, hashes, and relevant static checks on important payloads.

## Use Wine only when authorized

Do not use Wine as a default unpacker. Prefer `cabextract`, `innoextract`, and `msiextract`.

If static extraction fails and the user explicitly authorizes execution, use an isolated Wine prefix under `tmp/` and document the boundary:

```sh
WINEPREFIX="$RE_SHELL_ROOT/tmp/wine-prefix" wine inputs/setup.exe
```

Wine is not a sandbox. A Windows sample can still affect files exposed to WSL, including mounted Windows drives.

## Report results

Put durable output in `artifacts/<identifier>/`. Include:

- The original sample SHA-256 and file type.
- Architecture, subsystem, compiler or packer indicators, imports, exports, and signatures.
- Relevant strings, resources, configuration, persistence, and network behavior.
- The commands and tool versions used.
- A clear distinction between static findings, observed runtime behavior, and inference.

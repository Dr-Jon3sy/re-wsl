---
name: android
description: Analyze Android APK, XAPK, DEX, smali, resources, signing, and runtime behavior with the tools installed by re-wsl.
user-invocable: false
---

# Android reverse engineering

Use this skill for Android packages, Dalvik Executable (DEX) bytecode, smali, manifests, resources, native libraries, and explicitly authorized device instrumentation.

## Confirm the environment

Before analysis, run:

```sh
source scripts/env.sh
bash scripts/doctor.sh
```

The base environment provides `apktool`, `aapt`, `apksigner`, `adb`, `fastboot`, `apk-mitm`, Frida tools, radare2, Ghidra, Binwalk, YARA, pyaxmlparser, and hermes-dec.

It does not package `aapt2`, jadx, dex2jar, Bytecode Viewer, APKiD, APKEditor, bundletool, jnitrace, trueseeing, quark-engine, koodousfinder, simg2img, sdat2img, payload-dumper-go, or imgpatchtools. Install one of those tools before using its command.

## Triage the package

Create a sample-specific working directory and record the original hash:

```sh
mkdir -p tmp/app
sha256sum inputs/app.apk
file inputs/app.apk
unzip -l inputs/app.apk | head -n 200
```

Inspect package metadata and signatures:

```sh
aapt dump badging inputs/app.apk
aapt dump permissions inputs/app.apk
apksigner verify --verbose --print-certs inputs/app.apk
```

Use `aapt`, not `aapt2`, because the Ubuntu package installs the former.

## Decode resources and smali

Decode the package into `tmp/`:

```sh
apktool d -f inputs/app.apk -o tmp/app/apktool
```

Review `AndroidManifest.xml`, exported components, intent filters, network-security configuration, smali code, assets, and bundled native libraries. Do not execute extracted scripts or libraries.

Search for useful indicators:

```sh
rg -n 'https?://|api[_-]?key|secret|token|password|certificatePinner' tmp/app/apktool
```

Use `r2` or Ghidra for native `.so` files:

```sh
r2 -AA tmp/app/apktool/lib/arm64-v8a/libexample.so
```

## Inspect a manifest with Python

Use pyaxmlparser when a script needs structured Android package metadata:

```python
from pyaxmlparser import APK

apk = APK("inputs/app.apk")
print(apk.package)
print(apk.version_name)
print(apk.permissions)
```

Run the script with `uv run --frozen python`.

## Patch for an authorized proxy test

When the user has authorized modification of the application, write the patched package under `tmp/`:

```sh
apk-mitm inputs/app.apk --tmp-dir tmp/app/apk-mitm
```

Do not overwrite the original sample. Record the patched file's hash and identify it as modified in any report.

## Use a device only with authorization

Confirm the target device before running instrumentation:

```sh
adb devices -l
frida-ps -U
```

Use `adb`, Frida, or `scrcpy` only when the device or emulator is authorized for testing. `scrcpy` is installed only by `setup-wsl.sh --full`.

## Report results

Put durable output in `artifacts/<identifier>/`. Include:

- The original sample SHA-256.
- Package name, version, signing identity, and supported architectures.
- Exported components, permissions, network endpoints, and suspicious behavior.
- The commands and tool versions used.
- A clear distinction between static findings, observed runtime behavior, and inference.

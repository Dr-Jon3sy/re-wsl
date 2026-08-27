---
name: web
description: Analyze HTTP traffic, HAR files, APIs, WebSockets, Protocol Buffers, and network captures with the tools installed by re-wsl.
user-invocable: false
---

# Web reverse engineering

Use this skill for Hypertext Transfer Protocol (HTTP) traffic, HTTP Archive (HAR) files, application programming interfaces (APIs), WebSockets, Protocol Buffers, packet captures, and authorized proxy testing.

## Confirm the environment

Before analysis, run:

```sh
source scripts/env.sh
bash scripts/doctor.sh
```

The base environment provides mitmproxy, mitmdump, mitmweb, tshark, nmap, HTTPie, curl, the Protocol Buffers compiler (`protoc`), grpcio, grpcio-tools, protobuf, haralyzer, and Beautiful Soup.

The environment does not package protoscope, grpcurl, grpcui, curl-impersonate, websocat, or pup. Install one of those tools before using its command.

## Triage captures

Record the source hash before analysis:

```sh
mkdir -p tmp/web
sha256sum inputs/capture.har
file inputs/capture.har
```

For packet captures, summarize protocols and conversations:

```sh
tshark -r inputs/capture.pcapng -q -z io,phs
tshark -r inputs/capture.pcapng -q -z conv,tcp
```

Extract selected HTTP fields without replaying traffic:

```sh
tshark -r inputs/capture.pcapng -Y http.request \
  -T fields -e frame.number -e ip.dst -e http.host -e http.request.method -e http.request.uri
```

## Inspect HAR files with Python

Use haralyzer for structured request and response inspection:

```python
import json

from haralyzer import HarParser

with open("inputs/capture.har", encoding="utf-8") as handle:
    parser = HarParser(json.load(handle))

for page in parser.pages:
    for entry in page.entries:
        request = entry["request"]
        print(request["method"], request["url"])
```

Run the example with `uv run --frozen python`.

Redact authorization headers, cookies, tokens, personal data, and request bodies before placing excerpts in `artifacts/`.

## Inspect Protocol Buffers

Compile a known schema to Python:

```sh
mkdir -p tmp/web/proto
protoc --python_out=tmp/web/proto path/to/schema.proto
```

Use `python -m grpc_tools.protoc` when gRPC stubs are also needed:

```sh
uv run --frozen python -m grpc_tools.protoc \
  -I path/to/protos \
  --python_out=tmp/web/proto \
  --grpc_python_out=tmp/web/proto \
  path/to/protos/service.proto
```

Do not claim an unknown binary payload is Protocol Buffers without schema evidence or a documented inference.

## Send authorized test requests

Use HTTPie or curl for explicit, bounded requests:

```sh
http GET https://example.test/api/status
curl --fail-with-body --silent --show-error https://example.test/api/status
```

Do not replay captured credentials or mutate a production service unless the user explicitly authorizes the target and action.

## Run an authorized proxy

Start an interactive proxy:

```sh
mitmproxy --set confdir="$RE_SHELL_ROOT/tmp/mitmproxy"
```

For scriptable or headless capture, use `mitmdump` and write flows under `tmp/`:

```sh
mitmdump --set confdir="$RE_SHELL_ROOT/tmp/mitmproxy" -w tmp/web/flows.mitm
```

Installing the mitmproxy certificate changes trust behavior. Do so only on an authorized test device or profile.

## Report results

Put durable output in `artifacts/<identifier>/`. Include:

- Capture hashes and collection context.
- Hosts, endpoints, methods, protocols, schemas, and authentication mechanisms.
- Relevant request and response patterns with secrets redacted.
- The commands and tool versions used.
- A clear distinction between captured evidence, replayed behavior, and inference.

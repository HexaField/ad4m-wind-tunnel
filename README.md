# AD4M Link Language Integration Tests

Multi-device integration test harness that proves Perspective sync works between two separate AD4M executors running on different machines. Tests 8 link language protocols across LAN or Tailscale.

## What This Does

For each Link Language under test:

1. Creates a **Neighbourhood** on Device A with that language
2. **Joins** the Neighbourhood on Device B
3. Writes links on A → verifies they appear on B (**A→B sync**)
4. Writes links on B → verifies they appear on A (**B→A sync**)
5. Removes a link on A → verifies it disappears from B (**removal sync**)
6. Writes 10 links on A → verifies all appear on B (**batch sync**)
7. Reports **pass/fail per test, per language**

## Supported Languages

| Protocol | Infrastructure | Docker Compose |
|---|---|---|
| **Holochain** | None (public bootstrap/signal) | — |
| **ActivityPub** | None (executor built-in AP) | — |
| **AT Protocol** | PDS server | `docker-compose.atproto.yml` |
| **Nostr** | Relay (strfry) | `docker-compose.nostr.yml` |
| **Matrix** | Homeserver (Conduit) | `docker-compose.matrix.yml` |
| **Solid** | Pod server (CSS) | `docker-compose.solid.yml` |
| **IPFS** | kubo daemon | `docker-compose.ipfs.yml` |
| **Hypercore** | None (Hyperswarm DHT) | — |

## Prerequisites

- **AD4M executor** built on both machines (Rust binary)
- **SSH access** from your workstation to both machines (key-based, no password prompts)
- **Docker** on the infrastructure host (for protocols that need it)
- **jq** and **curl** installed locally and on both machines
- **nc** (netcat) for WebSocket readiness checks

## Quick Start

```bash
# 1. Configure
cp config.example.env config.env
vi config.env  # Set IPs, ports, language addresses

# 2. Start executors on both machines
./scripts/setup-executor.sh

# 3. Run all tests
./scripts/run-tests.sh
```

## Usage

### Run all language tests

```bash
./scripts/run-tests.sh
```

### Run a single language

```bash
./scripts/run-tests.sh --language nostr
./scripts/run-tests.sh -l holochain
```

### List available tests

```bash
./scripts/run-tests.sh --list
```

### Setup/teardown separately

```bash
# Start executors
./scripts/setup-executor.sh          # Both devices
./scripts/setup-executor.sh a        # Device A only

# Start infrastructure for a protocol
./scripts/setup-infra.sh nostr       # Single protocol
./scripts/setup-infra.sh all         # All protocols

# Stop everything
./scripts/teardown.sh                # Executors + infra
./scripts/teardown.sh --all          # + clean test data
./scripts/teardown.sh --infra        # Infrastructure only
```

### Select which languages to test via config

```bash
# In config.env:
LANGUAGES_TO_TEST=holochain,nostr    # Only these two
LANGUAGES_TO_TEST=all                # All languages (default)
```

## Configuration

Copy `config.example.env` to `config.env` and set:

| Variable | Description |
|---|---|
| `DEVICE_A_HOST` | IP/hostname of Device A |
| `DEVICE_A_USER` | SSH user for Device A |
| `DEVICE_A_PORT` | AD4M executor port on Device A (default: 12000) |
| `DEVICE_A_ADMIN` | Admin credential for Device A |
| `DEVICE_B_HOST` / `_USER` / `_PORT` / `_ADMIN` | Same for Device B |
| `EXECUTOR_BIN` | Path to ad4m-executor binary on both machines |
| `EXECUTOR_DATA_DIR` | Data directory for test runs |
| `SYNC_WAIT_SECONDS` | Max seconds to wait for sync (default: 10) |
| `LANG_HOLOCHAIN` | Language address/hash for Holochain link language |
| `LANG_NOSTR` | Language address/hash for Nostr link language |
| ... | One `LANG_*` variable per protocol |

Infrastructure URLs are optional — if not set, tests will use defaults based on `DEVICE_A_HOST`.

## Per-Language Notes

### Holochain
- **Zero infrastructure** — uses public Holochain bootstrap and signal servers
- May be slower to sync on first connection while DHT settles
- Consider increasing `SYNC_WAIT_SECONDS` for Holochain tests

### ActivityPub
- Relies on the AD4M executor's built-in ActivityPub server
- Both executors must be reachable from each other (no NAT issues)
- Port visibility matters — both executor ports must be open bidirectionally

### AT Protocol
- Runs a self-hosted PDS (Personal Data Server)
- The PDS docker-compose uses Bluesky's official image
- Both devices connect to the same PDS instance

### Nostr
- Uses a strfry relay in Docker
- Both devices publish/subscribe to the same relay
- Very fast sync (sub-second) when relay is local

### Matrix
- Uses Conduit (lightweight Rust homeserver)
- Both devices register accounts on the same homeserver
- Federation is enabled but not required for same-server tests

### Solid
- Uses Community Solid Server (CSS)
- Both devices access the same Solid pod server
- Data is stored as Linked Data in the pod

### IPFS
- Uses kubo (go-ipfs) daemon
- For true multi-device testing, run IPFS on both machines
- Set `IPFS_API_B` to Device B's IPFS endpoint

### Hypercore
- **Zero infrastructure** — uses Hyperswarm DHT (fully P2P)
- Discovery happens via DHT — both machines need outbound internet
- May take longer for initial peer discovery

## Test Results

Results are written as JSON to `results/`:

```
results/holochain-20260502T123456.json
results/nostr-20260502T123512.json
```

Each file contains:

```json
{
  "language": "holochain",
  "tests": [
    {"name": "A→B sync", "status": "PASS", "message": "", "timestamp": "2026-05-02T02:34:56Z"},
    {"name": "B→A sync", "status": "PASS", "message": "", "timestamp": "2026-05-02T02:35:06Z"},
    {"name": "Removal sync", "status": "FAIL", "message": "Removed link still present...", "timestamp": "2026-05-02T02:35:16Z"},
    {"name": "Batch sync (11 links)", "status": "PASS", "message": "", "timestamp": "2026-05-02T02:35:26Z"}
  ],
  "started": "2026-05-02T02:34:50Z",
  "finished": "2026-05-02T02:35:30Z",
  "passed": 3,
  "failed": 1,
  "skipped": 0
}
```

## Adding a New Language

1. Create `scripts/languages/test-<name>.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"
load_config

# If infrastructure is needed:
setup_my_infra() { start_infra "docker-compose.myproto.yml" ... }
teardown_my_infra() { stop_infra "docker-compose.myproto.yml" ... }

run_standard_tests "myprotocol" "${LANG_MYPROTOCOL:-}" setup_my_infra teardown_my_infra
```

2. Add a `LANG_MYPROTOCOL=` entry to `config.example.env`
3. If infrastructure is needed, add `infra/docker-compose.myproto.yml`
4. Add the language name to the `ALL_LANGUAGES` array in `scripts/run-tests.sh`
5. Make it executable: `chmod +x scripts/languages/test-myprotocol.sh`
6. Document in `INFRASTRUCTURE.md`

## Architecture

```
┌──────────┐     SSH      ┌──────────────────────────┐
│          │──────────────▶│ Device A (Ubuntu)        │
│  Test    │              │  ad4m-executor :12000     │
│  Runner  │              │  Docker infra (optional)  │
│  (your   │              └──────────────────────────┘
│  machine)│                        │
│          │     SSH      ┌──────────────────────────┐
│          │──────────────▶│ Device B (Ubuntu)        │
│          │              │  ad4m-executor :12000     │
└──────────┘              └──────────────────────────┘
                                    │
                          ┌─────────┴─────────┐
                          │   Neighbourhood    │
                          │   (Link Language)  │
                          │   syncs between    │
                          │   Device A ↔ B     │
                          └───────────────────┘
```

The test runner:
1. Connects to both machines via SSH
2. Starts AD4M executors (if using `setup-executor.sh`)
3. Starts required infrastructure (Docker containers)
4. Communicates with executors via GraphQL over HTTP
5. Creates neighbourhoods, writes links, asserts sync
6. Tears down everything on completion

## Troubleshooting

### Executor won't start
- Check `~/ad4m-test-data/executor.log` on the remote machine
- Ensure the binary is built: `cargo build --release` in the AD4M repo
- Verify the port isn't already in use

### SSH connection refused
- Ensure key-based SSH is configured (no password prompts)
- Check `StrictHostKeyChecking` isn't blocking new hosts
- For Tailscale: ensure both machines are on the same tailnet

### Sync timeout
- Increase `SYNC_WAIT_SECONDS` in config
- Check that both executors can reach each other's network
- For Holochain/Hypercore: initial DHT discovery takes time

### Infrastructure won't start
- Ensure Docker is installed and running on the target machine
- Check Docker Compose v2 is available (`docker compose version`)
- Review container logs: `docker logs ad4m-test-<container>`

## License

MIT

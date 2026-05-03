# AD4M Wind Tunnel

Performance testing framework for the [AD4M](https://github.com/coasys/ad4m) executor. Benchmarks core operations across branches to detect regressions and compare architectural approaches.

## Quick Start

```bash
# Install dependencies
npm install

# Run all scenarios against pre-built executors (skip-build mode)
npx tsx src/main.ts --skip-build

# Run specific scenario on specific branch
npx tsx src/main.ts --skip-build --branch dev --scenario s1

# Full run including builds (takes 10+ minutes per branch)
npx tsx src/main.ts
```

## Scenarios

| ID | Name | Description |
|----|------|-------------|
| **S1** | Cold Start | Full lifecycle: health → agent generation → first perspective → first link → first query |
| **S2** | Link Throughput | 500 sequential link additions with degradation tracking (first 50 vs last 50) |
| **S5** | Query Scaling | Query latency at 100/500/1000 link thresholds |
| **M1** | Neighbourhood Sync | Multi-executor baseline (full DHT sync requires language installation) |

## Architecture

```
src/
├── client.ts       # Instrumented HTTP/WS client (GraphQL + REST transports)
├── executor.ts     # Executor lifecycle (build, init, start, health, stop)
├── main.ts         # Runner orchestration
├── scenario.ts     # Scenario interface
├── scenarios/      # Individual scenario implementations
├── reporters.ts    # Console + JSON output
└── report.ts       # Comparison report generation
```

## Branch Transport Map

| Branch | Transport | API |
|--------|-----------|-----|
| `dev` | GraphQL | POST `/graphql` with `Authorization: <token>` |
| `feat/sparql-1.2-cleanup` | GraphQL | POST `/graphql` with `Authorization: <token>` |
| `feat/sse-to-websocket` | REST | GET/POST `/api/v1/*` with `Authorization: Bearer <token>` |

## CLI Options

| Flag | Description |
|------|-------------|
| `--skip-build` | Use pre-built binaries at `/tmp/ad4m-build-<branch>/target/release/ad4m-executor` |
| `--branch <name>` | Run only against specified branch (can repeat) |
| `--scenario <id>` | Run only specified scenario (can repeat) |
| `--executor-path <path>` | Use a single binary for all branches |

## Output

Results are saved to `results/<branch>/<scenario>.json` with a comparison report at `results/comparison.md`.

## Initial Results (Apple Silicon M3 Pro, 48GB)

### S1 — Cold Start

| Metric | dev | sse-to-websocket | sparql-1.2-cleanup |
|--------|-----|------------------|-------------------|
| Health check | 1.5ms | 1.7ms | 0.9ms |
| Agent generate | 8995ms | 9250ms | 9004ms |
| First perspective | 52ms | 58ms | 23ms |
| First link add | 1.3ms | 1.0ms | 1.0ms |
| First link query | 1.0ms | 0.9ms | 0.6ms |

### S2 — Link Throughput (500 links)

| Metric | dev | sse-to-websocket | sparql-1.2-cleanup |
|--------|-----|------------------|-------------------|
| Throughput | 53.5/s | 53.4/s | 53.1/s |
| Avg add latency | 1.4ms | 0.5ms | 0.4ms |
| P95 add latency | 1.7ms | 0.6ms | 0.4ms |
| Degradation ratio | 0.99x | 1.14x | 0.52x |

### S5 — Query Scaling

| Links | dev | sse-to-websocket | sparql-1.2-cleanup |
|-------|-----|------------------|-------------------|
| 100 | 0.39ms | 0.35ms | 0.32ms |
| 500 | 0.39ms | 0.39ms | 0.59ms |
| 1000 | 0.30ms | 0.31ms | 0.29ms |

All branches show **sublinear query scaling** — queries at 1000 links are faster than at 100 (cache warmup effect).

## Requirements

- Node.js 20+
- Rust toolchain (for building executors)
- `ad4m` repository cloned at `/Users/josh/workspaces/coasys/ad4m`
- `CUSTOM_DENO_SNAPSHOT.bin` present in the repo root

## License

MIT

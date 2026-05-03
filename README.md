# AD4M Wind Tunnel

Performance testing framework for the AD4M executor. Measures cold start time, link throughput, query scaling, and multi-executor behaviour across different branches.

## Quick Start

```bash
# Install dependencies
npm install

# Run all scenarios against all branches (includes build step ~15min per branch)
./run.sh

# Run with pre-built executors (skip build)
./run.sh --skip-build

# Run specific scenario
./run.sh --scenario s1

# Run against specific branch
./run.sh --branch dev
```

## Scenarios

| ID | Name | Description |
|----|------|-------------|
| S1 | Cold Start | Time from executor start to first successful operations |
| S2 | Link Throughput | Sustained link add/query rate, latency degradation over time |
| S5 | Query Scaling | Query latency vs data size (100, 500, 1000 links) |
| M1 | Neighbourhood Sync | Dual-executor baseline (perspective/link operations) |

## Architecture

```
src/
├── main.ts           # Runner/orchestrator
├── client.ts         # Instrumented AD4M client (REST + WebSocket)
├── executor.ts       # Executor lifecycle management (build/start/stop)
├── scenario.ts       # Scenario interface
├── reporters.ts      # Console + JSON reporters
├── report.ts         # Standalone report generator
└── scenarios/
    ├── s1-cold-start.ts
    ├── s2-link-throughput.ts
    ├── s5-query-scaling.ts
    └── m1-neighbourhood-sync.ts
```

## Results

Results are stored in `results/<branch-name>/` as JSON files per scenario, plus a `comparison.md` showing differences across branches.

## Branches Tested

- `dev` — current main development branch (REST API)
- `feat/sse-to-websocket` — WebSocket RPC transport
- `feat/sparql-1.2-cleanup` — Ad4mModel refactor, RDF Reifiers, optimisations (REST API)

## Requirements

- Node.js 20+
- Rust toolchain (for building executor)
- AD4M repo at `/Users/josh/workspaces/coasys/ad4m`
- ~15 minutes build time per branch on Apple Silicon

## Configuration

Edit `src/main.ts` constants:
- `AD4M_REPO` — path to AD4M repository
- `BASE_PORT` — starting port for executor instances
- `BRANCHES` — branch configurations

## Programmatic Usage

```typescript
import { InstrumentedClient } from "./src/client.js";

const client = new InstrumentedClient({
  port: 12100,
  adminToken: "test123",
  transport: "rest", // or "ws"
});

const result = await client.timed(() => client.addLink(uuid, source, pred, target));
console.log(`Took ${result.durationMs}ms`);
```

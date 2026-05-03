# Wind Tunnel Results: `feat/sse-to-websocket`

## Branch Highlights

The `feat/sse-to-websocket` branch replaces GraphQL + SSE with REST + WebSocket transport.

### Strengths
- **Memory efficiency champion**: 208MB idle (vs 553MB dev), 0.72 MB/min growth (vs 2.4 MB/min)
- **Flattest query scaling**: 0.93x at 1K links (effectively no degradation)
- **Fastest at scale**: 1M links in 306s with 0.2ms avg add latency, 1.7GB RSS
- **Zero multi-executor interference**: 1.02x factor
- **Best write throughput at scale**: 73,548 total links in M4 isolation test

### Weaknesses
- No MCP endpoint exposed
- No native SPARQL (falls back to link queries for subject class scenarios)
- Slightly slower cold start than SPARQL branch (15.3s vs 14.4s)

### Key Metrics vs Dev
| Metric | dev | feat/sse-to-websocket | Improvement |
|--------|-----|----------------------|-------------|
| Idle RSS | 553MB | 208MB | **2.7x lower** |
| Memory growth | 2.4 MB/min | 0.72 MB/min | **3.3x slower** |
| Query scaling (1K) | 19.4x degradation | 0.93x (flat) | **Regression fixed** |
| Million links | 702s | 306s | **2.3x faster** |
| Concurrent throughput | 239 ops/s | 248 ops/s | Marginal |
| Perspective RSS growth | 12MB/100 | 14MB/100 | Equivalent |

### Transport Characteristics
- WebSocket RPC: persistent connection, binary framing, multiplexed calls
- Event delivery via WS push (no SSE polling)
- Automatic reconnection with exponential backoff
- Subscription model built into WS protocol

# AD4M Wind Tunnel — Comparison Report

Generated: 2026-05-03T13:01:19.070Z
Machine: Apple Silicon MacBook Pro (48GB RAM, 14 CPUs)

## s1-cold-start

| Metric | dev | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- | --- |
| healthMs | 1.50 | 1.69 | 0.92 |
| agentGenerateMs | 8995.28 | 9250.40 | 9003.52 |
| firstPerspectiveCreateMs | 52.10 | 57.75 | 23.39 |
| firstLinkAddMs | 1.32 | 0.98 | 1.01 |
| firstLinkQueryMs | 1.05 | 0.91 | 0.57 |
| totalColdStartMs | 9051.00 | 9313.00 | 9030.00 |

**Summaries:**
- **dev:** Cold start complete in 9051ms (health: 2ms, agent: 8995ms, perspective: 52ms, link: 1ms, query: 1ms)
- **feat-sse-to-websocket:** Cold start complete in 9313ms (health: 2ms, agent: 9250ms, perspective: 58ms, link: 1ms, query: 1ms)
- **feat-sparql-1.2-cleanup:** Cold start complete in 9030ms (health: 1ms, agent: 9004ms, perspective: 23ms, link: 1ms, query: 1ms)

## s2-link-throughput

| Metric | dev | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- | --- |
| totalLinks | 500.00 | 500.00 | 500.00 |
| totalDurationMs | 9353.00 | 9363.00 | 9416.00 |
| throughputLinksPerSec | 53.50 | 53.40 | 53.10 |
| degradationRatio | 0.99 | 1.14 | 0.52 |
| queryAllMs | 1.70 | 0.62 | 0.41 |
| queryBySourceMs | 1.15 | 0.40 | 0.37 |
| addAvgMs | 1.42 | 0.51 | 0.39 |
| addP50Ms | 1.70 | 0.62 | 0.41 |
| addP95Ms | 1.70 | 0.62 | 0.41 |
| addP99Ms | 1.70 | 0.62 | 0.41 |

**Summaries:**
- **dev:** Added 500 links at 53.5 links/s. Avg add: 1.4ms, P95: 1.7ms. Degradation ratio: 0.99x
- **feat-sse-to-websocket:** Added 500 links at 53.4 links/s. Avg add: 0.5ms, P95: 0.6ms. Degradation ratio: 1.14x
- **feat-sparql-1.2-cleanup:** Added 500 links at 53.1 links/s. Avg add: 0.4ms, P95: 0.4ms. Degradation ratio: 0.52x

## s5-query-scaling

| Metric | dev | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- | --- |
| scalingFactor | 0.77 | 0.89 | 0.91 |
| totalLinksAdded | 1000.00 | 1000.00 | 1000.00 |

**Summaries:**
- **dev:** Query scaling (0.77x at 1000 vs 100 links):
  100 links: queryAll=0.39ms, queryBySource=0.4ms
  500 links: queryAll=0.39ms, queryBySource=0.39ms
  1000 links: queryAll=0.3ms, queryBySource=0.28ms
- **feat-sse-to-websocket:** Query scaling (0.89x at 1000 vs 100 links):
  100 links: queryAll=0.35ms, queryBySource=0.33ms
  500 links: queryAll=0.39ms, queryBySource=0.37ms
  1000 links: queryAll=0.31ms, queryBySource=0.28ms
- **feat-sparql-1.2-cleanup:** Query scaling (0.91x at 1000 vs 100 links):
  100 links: queryAll=0.32ms, queryBySource=0.3ms
  500 links: queryAll=0.59ms, queryBySource=1.93ms
  1000 links: queryAll=0.29ms, queryBySource=0.3ms

## m1-neighbourhood-sync

| Metric | dev | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- | --- |
| executor1AvgLinkAddMs | 0.00 | 0.00 | 0.00 |
| executor2AvgLinkAddMs | 0.00 | 0.00 | 0.00 |
| executor1LinkCount | 10.00 | 10.00 | 10.00 |
| executor2LinkCount | 10.00 | 10.00 | 10.00 |
| note | Full neighbourhood sync requires language installation (future iteration) | Full neighbourhood sync requires language installation (future iteration) | Full neighbourhood sync requires language installation (future iteration) |

**Summaries:**
- **dev:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).
- **feat-sse-to-websocket:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).
- **feat-sparql-1.2-cleanup:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).

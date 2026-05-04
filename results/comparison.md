# AD4M Wind Tunnel — Comparison Report

Generated: 2026-05-04T00:07:56.667Z
Machine: Apple Silicon MacBook Pro (48GB RAM, 14 CPUs)

## a1-mcp-throughput

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| mcpAvailable | true | true | false |
| iterations | 50.00 | 50.00 | — |
| errors | 50.00 | 50.00 | — |
| avgMs | 0.37 | 0.35 | — |
| p50Ms | 0.37 | 0.35 | — |
| p95Ms | 0.44 | 0.40 | — |
| p99Ms | 1.33 | 0.45 | — |
| minMs | 0.24 | 0.24 | — |
| maxMs | 1.33 | 0.45 | — |
| throughputCallsPerSec | 2381.00 | 2631.60 | — |
| status | — | — | STUB |
| note | — | — | MCP endpoint not available on this branch. The executor does not expose /mcp or /mcp/sse on the tested branches. |

**Summaries:**
- **dev:** MCP: 50 calls, avg 0.4ms, P95 0.4ms, 2381.0 calls/s, 50 errors
- **feat-sparql-1.2-cleanup:** MCP: 50 calls, avg 0.3ms, P95 0.4ms, 2631.6 calls/s, 50 errors
- **feat-sse-to-websocket:** STUB: MCP endpoint not available on branch feat/sse-to-websocket. Endpoint not exposed at /mcp or /mcp/sse.

## m1-neighbourhood-sync

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| executor1AvgLinkAddMs | 0.00 | 0.00 | 0.00 |
| executor2AvgLinkAddMs | 0.00 | 0.00 | 0.00 |
| executor1LinkCount | 10.00 | 10.00 | 10.00 |
| executor2LinkCount | 10.00 | 10.00 | 10.00 |
| note | Full neighbourhood sync requires language installation (future iteration) | Full neighbourhood sync requires language installation (future iteration) | Full neighbourhood sync requires language installation (future iteration) |

**Summaries:**
- **dev:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).
- **feat-sparql-1.2-cleanup:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).
- **feat-sse-to-websocket:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).

## m2-multi-executor-scale

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| degradationFactor | 0.94 | 0.87 | 1.02 |

**Summaries:**
- **dev:** Single: avg 0.6ms. Multi (3 executors): avg 0.6ms. Degradation: 0.94x
- **feat-sparql-1.2-cleanup:** Single: avg 0.6ms. Multi (3 executors): avg 0.5ms. Degradation: 0.87x
- **feat-sse-to-websocket:** Single: avg 0.6ms. Multi (3 executors): avg 0.6ms. Degradation: 1.02x

## m3-link-language-comparison

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| dockerStartupMs | 21727.00 | 445.00 | 1771.00 |
| serviceHealthWaitMs | 121958.00 | 121028.00 | 122094.00 |
| note | Full link language comparison requires language installation (future iteration). This measures infrastructure readiness and local baseline. | Full link language comparison requires language installation (future iteration). This measures infrastructure readiness and local baseline. | Full link language comparison requires language installation (future iteration). This measures infrastructure readiness and local baseline. |

**Summaries:**
- **dev:** Docker infra: 1/5 healthy in 122.0s. Local baseline at 1000 links: add=0.9ms, query=0ms, 1137 links/s
- **feat-sparql-1.2-cleanup:** Docker infra: 1/5 healthy in 121.0s. Local baseline at 1000 links: add=0.6ms, query=0ms, 1821 links/s
- **feat-sse-to-websocket:** Docker infra: 1/5 healthy in 122.1s. Local baseline at 1000 links: add=0.5ms, query=0ms, 1879 links/s

## m4-write-load-under-sync

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| mode | isolation_test | isolation_test | isolation_test |
| note | Neighbourhood sync not available; measuring cross-executor interference via resource contention | Neighbourhood sync not available; measuring cross-executor interference via resource contention | Neighbourhood sync not available; measuring cross-executor interference via resource contention |
| interferenceFactor | 0.69 | 0.60 | 0.56 |
| totalLinksWritten | 46611.00 | 56280.00 | 73548.00 |

**Summaries:**
- **dev:** Isolation test: isolated=1.1ms, concurrent=0.8ms/0.8ms, interference=0.69x. RSS: E1=336MB, E2=336MB
- **feat-sparql-1.2-cleanup:** Isolation test: isolated=1.7ms, concurrent=1.0ms/1.0ms, interference=0.6x. RSS: E1=349MB, E2=349MB
- **feat-sse-to-websocket:** Isolation test: isolated=1.8ms, concurrent=1.0ms/1.0ms, interference=0.56x. RSS: E1=336MB, E2=336MB

## m5-concurrent-neighbourhoods

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| mode | multi_perspective_isolation_test | multi_perspective_isolation_test | multi_perspective_isolation_test |
| note | Neighbourhood sync not available; measuring multi-executor/multi-perspective resource contention | Neighbourhood sync not available; measuring multi-executor/multi-perspective resource contention | Neighbourhood sync not available; measuring multi-executor/multi-perspective resource contention |
| executorCount | 3.00 | 3.00 | 3.00 |
| perspectivesPerExecutor | 3.00 | 3.00 | 3.00 |
| totalLinksWritten | 62013.00 | 64474.00 | 72474.00 |

**Summaries:**
- **dev:** 3 executors × 3 perspectives: single=1.1ms, multi=0.8ms (0.66x), pressure=0.9ms (0.81x). RSS growth: -72MB/persp, -69MB/persp, 62MB/persp
- **feat-sparql-1.2-cleanup:** 3 executors × 3 perspectives: single=1.2ms, multi=1.0ms (0.87x), pressure=0.9ms (0.74x). RSS growth: -71MB/persp, -76MB/persp, 62MB/persp
- **feat-sse-to-websocket:** 3 executors × 3 perspectives: single=1.2ms, multi=1.1ms (0.91x), pressure=0.8ms (0.64x). RSS growth: -70MB/persp, -68MB/persp, 64MB/persp

## s1-cold-start

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| healthMs | 1.65 | 0.84 | 2.83 |
| agentGenerateMs | 15714.65 | 14360.42 | 15289.86 |
| firstPerspectiveCreateMs | 54.48 | 14.71 | 43.74 |
| firstLinkAddMs | 1.51 | 0.90 | 10.73 |
| firstLinkQueryMs | 1.16 | 0.66 | 1.84 |
| totalColdStartMs | 15774.00 | 14378.00 | 15349.00 |

**Summaries:**
- **dev:** Cold start complete in 15774ms (health: 2ms, agent: 15715ms, perspective: 54ms, link: 2ms, query: 1ms)
- **feat-sparql-1.2-cleanup:** Cold start complete in 14378ms (health: 1ms, agent: 14360ms, perspective: 15ms, link: 1ms, query: 1ms)
- **feat-sse-to-websocket:** Cold start complete in 15349ms (health: 3ms, agent: 15290ms, perspective: 44ms, link: 11ms, query: 2ms)

## s10-subscription-fanout

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| latencyScalingFactor | 41.58 | 5.37 | 0.00 |
| memoryPerSubscriberKb | 246.00 | 176.00 | 71.00 |

**Summaries:**
- **dev:** Tested 5,10,25,50,100 subscriber tiers. At 100 subs: avgLat=304.3ms, P95=1012.9ms Latency scaling: 41.58x Backpressure: slow sub DOES affect others
- **feat-sparql-1.2-cleanup:** Tested 5,10,25,50,100 subscriber tiers. At 100 subs: avgLat=65.1ms, P95=1006.7ms Latency scaling: 5.37x Backpressure: slow sub DOES affect others
- **feat-sse-to-websocket:** Tested 5,10,25,50,100 subscriber tiers. At 100 subs: avgLat=0.0ms, P95=0.0ms Latency scaling: 0.00x Backpressure: slow sub does NOT affect others

## s12-persistence-cold-query

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| seedLinkCount | 100000.00 | 100000.00 | 100000.00 |
| seedDurationMs | 140487.00 | 126332.00 | 25766.00 |
| seedThroughputLinksPerSec | 711.80 | 791.60 | 3881.00 |
| emptyStartupMs | 505.00 | 507.00 | 505.00 |
| coldRestartMs | 505.00 | 505.00 | 504.00 |
| startupTimeDeltaMs | 1.00 | -2.00 | 0.00 |
| startupSlowdownFactor | 1.00 | 1.00 | 1.00 |
| coldQueryAllMs | 3.16 | 3.00 | 2.87 |
| coldQueryBySourceMs | 1.47 | 0.92 | 1.12 |
| coldQueryByPredicateMs | 0.66 | 0.59 | 0.65 |
| warmupP50Ms | 0.36 | 0.48 | 0.48 |
| warmupFirstMs | 0.49 | 0.44 | 0.61 |
| warmupLastMs | 0.33 | 0.29 | 0.46 |
| warmupImprovement | 1.48 | 1.55 | 1.33 |
| rssAfterSeedMb | 322.00 | 314.00 | 335.00 |
| rssAfterColdMb | 322.00 | 315.00 | 335.00 |

**Summaries:**
- **dev:** 100000 links seeded. Startup: empty=505ms, cold=505ms (1.0x slower). Cold queryAll: 3ms, bySource: 1ms. Warmup: first=0ms → last=0ms.
- **feat-sparql-1.2-cleanup:** 100000 links seeded. Startup: empty=507ms, cold=505ms (1.0x slower). Cold queryAll: 3ms, bySource: 1ms. Warmup: first=0ms → last=0ms.
- **feat-sse-to-websocket:** 100000 links seeded. Startup: empty=505ms, cold=504ms (1.0x slower). Cold queryAll: 3ms, bySource: 1ms. Warmup: first=1ms → last=0ms.

## s13-read-write-mix

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| seedLinks | 10000.00 | 10000.00 | 10000.00 |
| seedDurationMs | 13936.00 | 12022.00 | 3577.00 |
| durationPerConfigSec | 30.00 | 30.00 | 30.00 |

**Summaries:**
- **dev:** Tested 1w/5r, 5w/5r, 5w/25r. At 5w/25r: write avg=1493.3ms P95=2886.6ms, read avg=4428.1ms P95=5898.6ms Consistency: OK
- **feat-sparql-1.2-cleanup:** Tested 1w/5r, 5w/5r, 5w/25r. At 5w/25r: write avg=1556.6ms P95=3394.7ms, read avg=5655.3ms P95=6850.2ms Consistency: OK
- **feat-sse-to-websocket:** Tested 1w/5r, 5w/5r, 5w/25r. At 5w/25r: write avg=1.5ms P95=2.8ms, read avg=1.9ms P95=3.9ms Consistency: OK

## s14-multi-perspective-load

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| perspectiveCount | 20.00 | 20.00 | 20.00 |
| linksPerPerspective | 5000.00 | 5000.00 | 5000.00 |
| totalLinks | 100000.00 | 100000.00 | 100000.00 |

**Summaries:**
- **dev:** 20 perspectives × 5000 links = 100000 total. Degradation P1→P20: add 0.98x, query 1.05x. P1 addAvg=1.4ms → P20 addAvg=1.4ms. RSS delta: 186MB total (9.3MB/perspective).
- **feat-sparql-1.2-cleanup:** 20 perspectives × 5000 links = 100000 total. Degradation P1→P20: add 0.94x, query 0.95x. P1 addAvg=1.3ms → P20 addAvg=1.2ms. RSS delta: 194MB total (9.7MB/perspective).
- **feat-sse-to-websocket:** 20 perspectives × 5000 links = 100000 total. Degradation P1→P20: add 0.33x, query 0.07x. P1 addAvg=0.5ms → P20 addAvg=0.2ms. RSS delta: 186MB total (9.3MB/perspective).

## s2-link-throughput

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| totalLinks | 500.00 | 500.00 | 500.00 |
| totalDurationMs | 18567.00 | 14667.00 | 16630.00 |
| throughputLinksPerSec | 26.90 | 34.10 | 30.10 |
| degradationRatio | 1.53 | 4.07 | 0.71 |
| queryAllMs | 0.69 | 0.46 | 1.15 |
| queryBySourceMs | 5.66 | 0.44 | 3.83 |
| addAvgMs | 3.17 | 0.45 | 2.49 |
| addP50Ms | 5.66 | 0.46 | 3.83 |
| addP95Ms | 5.66 | 0.46 | 3.83 |
| addP99Ms | 5.66 | 0.46 | 3.83 |

**Summaries:**
- **dev:** Added 500 links at 26.9 links/s. Avg add: 3.2ms, P95: 5.7ms. Degradation ratio: 1.53x
- **feat-sparql-1.2-cleanup:** Added 500 links at 34.1 links/s. Avg add: 0.5ms, P95: 0.5ms. Degradation ratio: 4.07x
- **feat-sse-to-websocket:** Added 500 links at 30.1 links/s. Avg add: 2.5ms, P95: 3.8ms. Degradation ratio: 0.71x

## s2b-million-links

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| totalLinksAdded | 1000000.00 | 1000000.00 | 1000000.00 |
| ceilingHit | false | false | false |
| totalDurationMs | 701559.00 | 327760.00 | 305735.00 |

**Summaries:**
- **dev:** Added 1000000 links total. Final tier: avg=0.7ms, P95=0.6ms, queryAll=2ms, RSS=2296MB Completed all tiers.
- **feat-sparql-1.2-cleanup:** Added 1000000 links total. Final tier: avg=0.3ms, P95=0.8ms, queryAll=5ms, RSS=2285MB Completed all tiers.
- **feat-sse-to-websocket:** Added 1000000 links total. Final tier: avg=0.2ms, P95=0.4ms, queryAll=5ms, RSS=1740MB Completed all tiers.

## s3-perspective-scaling

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| totalPerspectivesCreated | 100.00 | 100.00 | 100.00 |
| totalLinksAdded | 500.00 | 500.00 | 500.00 |
| rssGrowthKb | 12544.00 | 275872.00 | 14304.00 |

**Summaries:**
- **dev:** Created 100 perspectives. Avg create time: 49.4ms at 100 perspectives (0.98x degradation from 10). RSS growth: 12.3MB
- **feat-sparql-1.2-cleanup:** Created 100 perspectives. Avg create time: 12.6ms at 100 perspectives (0.96x degradation from 10). RSS growth: 269.4MB
- **feat-sse-to-websocket:** Created 100 perspectives. Avg create time: 49.6ms at 100 perspectives (0.75x degradation from 10). RSS growth: 14.0MB

## s4-language-install-storm

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| initialRssKb | 209168.00 | 561376.00 | 189920.00 |
| finalRssKb | 213968.00 | 596672.00 | 212272.00 |
| rssGrowthKb | 4800.00 | 35296.00 | 22352.00 |
| note | Full language installation testing requires languageApplyTemplateAndPublish API and template languages. This scenario uses concurrent perspective+link operations as a load proxy. | Full language installation testing requires languageApplyTemplateAndPublish API and template languages. This scenario uses concurrent perspective+link operations as a load proxy. | Full language installation testing requires languageApplyTemplateAndPublish API and template languages. This scenario uses concurrent perspective+link operations as a load proxy. |

**Summaries:**
- **dev:** Concurrent batches [5,10,20]: Last batch (20 concurrent) avg create: 166.1ms, avg link: 25.1ms, 200 errors. RSS growth: 4.7MB
- **feat-sparql-1.2-cleanup:** Concurrent batches [5,10,20]: Last batch (20 concurrent) avg create: 50.6ms, avg link: 34.8ms, 200 errors. RSS growth: 34.5MB
- **feat-sse-to-websocket:** Concurrent batches [5,10,20]: Last batch (20 concurrent) avg create: 178.9ms, avg link: 29.5ms, 200 errors. RSS growth: 21.8MB

## s5-query-scaling

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| scalingFactor | 19.43 | 1.22 | 0.93 |
| totalLinksAdded | 1000.00 | 1000.00 | 1000.00 |

**Summaries:**
- **dev:** Query scaling (19.43x at 1000 vs 100 links):
  100 links: queryAll=0.93ms, queryBySource=0.81ms
  500 links: queryAll=1.1ms, queryBySource=0.63ms
  1000 links: queryAll=18.07ms, queryBySource=10.59ms
- **feat-sparql-1.2-cleanup:** Query scaling (1.22x at 1000 vs 100 links):
  100 links: queryAll=0.45ms, queryBySource=0.46ms
  500 links: queryAll=2.38ms, queryBySource=1.27ms
  1000 links: queryAll=0.55ms, queryBySource=0.75ms
- **feat-sse-to-websocket:** Query scaling (0.93x at 1000 vs 100 links):
  100 links: queryAll=0.54ms, queryBySource=0.43ms
  500 links: queryAll=0.5ms, queryBySource=0.61ms
  1000 links: queryAll=0.5ms, queryBySource=0.48ms

## s6-api-concurrency

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| scalingFactor | 3.40 | 3.77 | 3.25 |

**Summaries:**
- **dev:** Concurrency levels [5,10,25]: At 25 clients: avg 93.4ms, P95 324.9ms, 239 ops/s, 350 errors. Scaling factor: 3.4x
- **feat-sparql-1.2-cleanup:** Concurrency levels [5,10,25]: At 25 clients: avg 22.5ms, P95 70.7ms, 1023 ops/s, 350 errors. Scaling factor: 3.77x
- **feat-sse-to-websocket:** Concurrency levels [5,10,25]: At 25 clients: avg 89.1ms, P95 335.5ms, 248 ops/s, 175 errors. Scaling factor: 3.25x

## s7-memory-stability

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| durationMs | 300000.00 | 300000.00 | 300000.00 |
| linksAdded | 295.00 | 295.00 | 295.00 |
| queriesPerformed | 29.00 | 29.00 | 29.00 |
| perspectivesCreated | 5.00 | 5.00 | 5.00 |

**Summaries:**
- **dev:** 5-min run: 295 links, 29 queries, 5 perspectives. Link avg: 1.1ms. RSS: 553MB → 565MB (2.4MB/min, growing)
- **feat-sparql-1.2-cleanup:** 5-min run: 295 links, 29 queries, 5 perspectives. Link avg: 1.1ms. RSS: 544MB → 556MB (2.4MB/min, growing)
- **feat-sse-to-websocket:** 5-min run: 295 links, 29 queries, 5 perspectives. Link avg: 1.2ms. RSS: 208MB → 212MB (0.72MB/min, slow_growth)

## s8-subject-class-queries

| Metric | dev | feat-sparql-1.2-cleanup | feat-sse-to-websocket |
| --- | --- | --- | --- |
| sparqlAvailable | true | true | false |

**Summaries:**
- **dev:** SPARQL: yes. small: 1867 links, seed=1.9s, slowest=subgroupItemsData@1ms. medium: 58365 links, seed=47.3s, slowest=totalItemCount@1ms
- **feat-sparql-1.2-cleanup:** SPARQL: yes. small: 1874 links, seed=0.9s, slowest=paginatedMessages@4ms. medium: 58420 links, seed=19.3s, slowest=subgroupTopics@1ms
- **feat-sse-to-websocket:** SPARQL: no (link query fallback). small: 1877 links, seed=1.7s, slowest=totalItemCount@1ms. medium: 58424 links, seed=29.0s, slowest=subgroupItemsData@0ms

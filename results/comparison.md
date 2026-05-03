# AD4M Wind Tunnel — Comparison Report

Generated: 2026-05-03T13:31:32.183Z
Machine: Apple Silicon MacBook Pro (48GB RAM, 14 CPUs)

## s1-cold-start

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| healthMs | 2.83 | 0.84 |
| agentGenerateMs | 15289.86 | 14360.42 |
| firstPerspectiveCreateMs | 43.74 | 14.71 |
| firstLinkAddMs | 10.73 | 0.90 |
| firstLinkQueryMs | 1.84 | 0.66 |
| totalColdStartMs | 15349.00 | 14378.00 |

**Summaries:**
- **feat-sse-to-websocket:** Cold start complete in 15349ms (health: 3ms, agent: 15290ms, perspective: 44ms, link: 11ms, query: 2ms)
- **feat-sparql-1.2-cleanup:** Cold start complete in 14378ms (health: 1ms, agent: 14360ms, perspective: 15ms, link: 1ms, query: 1ms)

## s2-link-throughput

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| totalLinks | 500.00 | 500.00 |
| totalDurationMs | 16630.00 | 14667.00 |
| throughputLinksPerSec | 30.10 | 34.10 |
| degradationRatio | 0.71 | 4.07 |
| queryAllMs | 1.15 | 0.46 |
| queryBySourceMs | 3.83 | 0.44 |
| addAvgMs | 2.49 | 0.45 |
| addP50Ms | 3.83 | 0.46 |
| addP95Ms | 3.83 | 0.46 |
| addP99Ms | 3.83 | 0.46 |

**Summaries:**
- **feat-sse-to-websocket:** Added 500 links at 30.1 links/s. Avg add: 2.5ms, P95: 3.8ms. Degradation ratio: 0.71x
- **feat-sparql-1.2-cleanup:** Added 500 links at 34.1 links/s. Avg add: 0.5ms, P95: 0.5ms. Degradation ratio: 4.07x

## s3-perspective-scaling

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| totalPerspectivesCreated | 100.00 | 100.00 |
| totalLinksAdded | 500.00 | 500.00 |
| rssGrowthKb | 14304.00 | 275872.00 |

**Summaries:**
- **feat-sse-to-websocket:** Created 100 perspectives. Avg create time: 49.6ms at 100 perspectives (0.75x degradation from 10). RSS growth: 14.0MB
- **feat-sparql-1.2-cleanup:** Created 100 perspectives. Avg create time: 12.6ms at 100 perspectives (0.96x degradation from 10). RSS growth: 269.4MB

## s4-language-install-storm

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| initialRssKb | 189920.00 | 561376.00 |
| finalRssKb | 212272.00 | 596672.00 |
| rssGrowthKb | 22352.00 | 35296.00 |
| note | Full language installation testing requires languageApplyTemplateAndPublish API and template languages. This scenario uses concurrent perspective+link operations as a load proxy. | Full language installation testing requires languageApplyTemplateAndPublish API and template languages. This scenario uses concurrent perspective+link operations as a load proxy. |

**Summaries:**
- **feat-sse-to-websocket:** Concurrent batches [5,10,20]: Last batch (20 concurrent) avg create: 178.9ms, avg link: 29.5ms, 200 errors. RSS growth: 21.8MB
- **feat-sparql-1.2-cleanup:** Concurrent batches [5,10,20]: Last batch (20 concurrent) avg create: 50.6ms, avg link: 34.8ms, 200 errors. RSS growth: 34.5MB

## s5-query-scaling

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| scalingFactor | 0.93 | 1.22 |
| totalLinksAdded | 1000.00 | 1000.00 |

**Summaries:**
- **feat-sse-to-websocket:** Query scaling (0.93x at 1000 vs 100 links):
  100 links: queryAll=0.54ms, queryBySource=0.43ms
  500 links: queryAll=0.5ms, queryBySource=0.61ms
  1000 links: queryAll=0.5ms, queryBySource=0.48ms
- **feat-sparql-1.2-cleanup:** Query scaling (1.22x at 1000 vs 100 links):
  100 links: queryAll=0.45ms, queryBySource=0.46ms
  500 links: queryAll=2.38ms, queryBySource=1.27ms
  1000 links: queryAll=0.55ms, queryBySource=0.75ms

## s6-api-concurrency

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| scalingFactor | 3.25 | 3.77 |

**Summaries:**
- **feat-sse-to-websocket:** Concurrency levels [5,10,25]: At 25 clients: avg 89.1ms, P95 335.5ms, 248 ops/s, 175 errors. Scaling factor: 3.25x
- **feat-sparql-1.2-cleanup:** Concurrency levels [5,10,25]: At 25 clients: avg 22.5ms, P95 70.7ms, 1023 ops/s, 350 errors. Scaling factor: 3.77x

## s7-memory-stability

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| durationMs | 300000.00 | 300000.00 |
| linksAdded | 295.00 | 295.00 |
| queriesPerformed | 29.00 | 29.00 |
| perspectivesCreated | 5.00 | 5.00 |

**Summaries:**
- **feat-sse-to-websocket:** 5-min run: 295 links, 29 queries, 5 perspectives. Link avg: 1.2ms. RSS: 208MB → 212MB (0.72MB/min, slow_growth)
- **feat-sparql-1.2-cleanup:** 5-min run: 295 links, 29 queries, 5 perspectives. Link avg: 1.1ms. RSS: 544MB → 556MB (2.4MB/min, growing)

## m1-neighbourhood-sync

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| executor1AvgLinkAddMs | 0.00 | 0.00 |
| executor2AvgLinkAddMs | 0.00 | 0.00 |
| executor1LinkCount | 10.00 | 10.00 |
| executor2LinkCount | 10.00 | 10.00 |
| note | Full neighbourhood sync requires language installation (future iteration) | Full neighbourhood sync requires language installation (future iteration) |

**Summaries:**
- **feat-sse-to-websocket:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).
- **feat-sparql-1.2-cleanup:** Dual-executor baseline: Exec1 avg link add: 0.0ms, Exec2: 0.0ms. Full sync test deferred (requires language installation).

## m2-multi-executor-scale

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| degradationFactor | 1.02 | 0.87 |

**Summaries:**
- **feat-sse-to-websocket:** Single: avg 0.6ms. Multi (3 executors): avg 0.6ms. Degradation: 1.02x
- **feat-sparql-1.2-cleanup:** Single: avg 0.6ms. Multi (3 executors): avg 0.5ms. Degradation: 0.87x

## m3-link-language-comparison

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| status | STUB | STUB |

**Summaries:**
- **feat-sse-to-websocket:** STUB: Requires Docker Compose infrastructure (Matrix/Nostr/IPFS). See scenario file for requirements.
- **feat-sparql-1.2-cleanup:** STUB: Requires Docker Compose infrastructure (Matrix/Nostr/IPFS). See scenario file for requirements.

## m4-write-load-under-sync

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| status | STUB | STUB |

**Summaries:**
- **feat-sse-to-websocket:** STUB: Requires neighbourhood sync infrastructure (Holochain + link language). See scenario file for requirements.
- **feat-sparql-1.2-cleanup:** STUB: Requires neighbourhood sync infrastructure (Holochain + link language). See scenario file for requirements.

## m5-concurrent-neighbourhoods

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| status | STUB | STUB |

**Summaries:**
- **feat-sse-to-websocket:** STUB: Requires multi-executor neighbourhood sync infrastructure (6+ executors, Holochain). See scenario file for requirements.
- **feat-sparql-1.2-cleanup:** STUB: Requires multi-executor neighbourhood sync infrastructure (6+ executors, Holochain). See scenario file for requirements.

## a1-mcp-throughput

| Metric | feat-sse-to-websocket | feat-sparql-1.2-cleanup |
| --- | --- | --- |
| status | STUB | — |
| mcpAvailable | false | true |
| note | MCP endpoint not available on this branch. The executor does not expose /mcp or /mcp/sse on the tested branches. | — |
| iterations | — | 50.00 |
| errors | — | 50.00 |
| avgMs | — | 0.35 |
| p50Ms | — | 0.35 |
| p95Ms | — | 0.40 |
| p99Ms | — | 0.45 |
| minMs | — | 0.24 |
| maxMs | — | 0.45 |
| throughputCallsPerSec | — | 2631.60 |

**Summaries:**
- **feat-sse-to-websocket:** STUB: MCP endpoint not available on branch feat/sse-to-websocket. Endpoint not exposed at /mcp or /mcp/sse.
- **feat-sparql-1.2-cleanup:** MCP: 50 calls, avg 0.3ms, P95 0.4ms, 2631.6 calls/s, 50 errors

/**
 * M3: Link Language Comparison (Stub)
 * Requires external infrastructure: Docker Compose for Matrix/Nostr/IPFS link languages.
 * This scenario creates the structure but cannot run without the infrastructure.
 */

import { Scenario, ScenarioContext, ScenarioResult } from "../scenario.js";

export const m3LinkLanguageComparison: Scenario = {
  id: "m3",
  name: "Link Language Comparison",
  description: "Compare throughput across different link languages (Matrix, Nostr, IPFS, local)",

  async run(ctx: ScenarioContext): Promise<ScenarioResult> {
    const { branch } = ctx;
    const startTime = Date.now();

    // This scenario requires:
    // 1. Docker Compose running Matrix Synapse, Nostr relay, IPFS node
    // 2. Link languages installed for each backend:
    //    - matrix-link-language
    //    - nostr-link-language
    //    - ipfs-link-language
    //    - local (default, no external deps)
    // 3. Neighbourhoods created with each link language
    //
    // Test plan:
    // - Create a perspective with each link language
    // - Add 100 links to each
    // - Measure: add latency, query latency, sync time
    // - Compare throughput and reliability across backends
    //
    // Infrastructure requirements:
    // - docker-compose.yml with:
    //   - synapse (Matrix homeserver)
    //   - nostr-relay (e.g. strfry)
    //   - ipfs (go-ipfs or kubo)
    // - Language bundles compiled and available
    // - AD4M executor configured with holochain bootstrap + proxy

    const endTime = Date.now();

    return {
      scenario: "m3-link-language-comparison",
      branch,
      startTime,
      endTime,
      durationMs: endTime - startTime,
      metrics: {
        status: "STUB",
        requiresInfrastructure: [
          "Docker Compose with Matrix Synapse",
          "Nostr relay (strfry or similar)",
          "IPFS node (kubo)",
          "Compiled link language bundles for each backend",
          "Holochain bootstrap and proxy services",
        ],
        plannedLanguages: ["matrix", "nostr", "ipfs", "local"],
        plannedMetrics: ["addLatencyMs", "queryLatencyMs", "syncTimeMs", "reliability"],
      },
      samples: [],
      summary: "STUB: Requires Docker Compose infrastructure (Matrix/Nostr/IPFS). See scenario file for requirements.",
    };
  },
};

/**
 * M5: Concurrent Neighbourhoods (Stub)
 * Tests performance with multiple active neighbourhoods syncing simultaneously.
 * Requires full neighbourhood infrastructure.
 */

import { Scenario, ScenarioContext, ScenarioResult } from "../scenario.js";

export const m5ConcurrentNeighbourhoods: Scenario = {
  id: "m5",
  name: "Concurrent Neighbourhoods",
  description: "Multiple active neighbourhoods syncing simultaneously, measure interference",

  async run(ctx: ScenarioContext): Promise<ScenarioResult> {
    const { branch } = ctx;
    const startTime = Date.now();

    // This scenario requires:
    // 1. 3+ executors with neighbourhood sync operational
    // 2. Multiple link languages (or same language, different neighbourhoods)
    // 3. Concurrent read/write across all neighbourhoods
    //
    // Test plan:
    // - Create N neighbourhoods (3, 5, 10)
    // - Each neighbourhood has 2 executors (creator + joiner)
    // - All neighbourhoods active simultaneously
    // - Write 10 links/s to each neighbourhood
    // - Measure:
    //   - Per-neighbourhood sync latency
    //   - Cross-neighbourhood interference (does sync on NH-A slow down NH-B?)
    //   - Total memory footprint with N active neighbourhoods
    //   - CPU utilisation scaling
    //   - Whether holochain conductors interfere at scale
    //
    // Infrastructure requirements:
    // - Multiple executors (6+ for 3 neighbourhoods)
    // - Neighbourhood sync fully operational
    // - Link languages installed and configured
    // - Holochain bootstrap + signal server
    // - Sufficient system resources (each executor uses ~200-500MB)

    const endTime = Date.now();

    return {
      scenario: "m5-concurrent-neighbourhoods",
      branch,
      startTime,
      endTime,
      durationMs: endTime - startTime,
      metrics: {
        status: "STUB",
        requiresInfrastructure: [
          "6+ executors for 3 concurrent neighbourhoods",
          "Neighbourhood sync fully operational",
          "Link languages installed and configured",
          "Holochain bootstrap + signal server",
          "~2-3GB available RAM for executor instances",
        ],
        plannedNeighbourhoodCounts: [3, 5, 10],
        plannedMetrics: [
          "perNeighbourhoodSyncLatencyMs",
          "crossNeighbourhoodInterference",
          "totalMemoryFootprintMb",
          "cpuUtilisationScaling",
          "holochainConductorInterference",
        ],
      },
      samples: [],
      summary: "STUB: Requires multi-executor neighbourhood sync infrastructure (6+ executors, Holochain). See scenario file for requirements.",
    };
  },
};

/**
 * M4: Write Load Under Sync (Stub)
 * Requires neighbourhood sync working between executors with a shared link language.
 * Tests write performance while sync is active.
 */

import { Scenario, ScenarioContext, ScenarioResult } from "../scenario.js";

export const m4WriteLoadUnderSync: Scenario = {
  id: "m4",
  name: "Write Load Under Sync",
  description: "Measure write throughput while neighbourhood sync is active",

  async run(ctx: ScenarioContext): Promise<ScenarioResult> {
    const { branch } = ctx;
    const startTime = Date.now();

    // This scenario requires:
    // 1. Two executors with neighbourhood sync operational
    // 2. A shared link language installed on both executors
    // 3. A neighbourhood created and joined by both executors
    //
    // Test plan:
    // - Set up 2 executors in a shared neighbourhood
    // - Executor 1 writes links at increasing rates (10/s, 50/s, 100/s)
    // - Executor 2 observes incoming sync'd links
    // - Measure:
    //   - Write latency on executor 1 (with sync overhead)
    //   - Sync propagation delay (time for executor 2 to see executor 1's links)
    //   - Write throughput ceiling before sync breaks down
    //   - Memory usage under sustained sync load
    //
    // Infrastructure requirements:
    // - Neighbourhood sync working (requires Holochain conductor + link language)
    // - At minimum: local link language with sync support
    // - Holochain bootstrap service
    // - Signal server for peer discovery

    const endTime = Date.now();

    return {
      scenario: "m4-write-load-under-sync",
      branch,
      startTime,
      endTime,
      durationMs: endTime - startTime,
      metrics: {
        status: "STUB",
        requiresInfrastructure: [
          "Neighbourhood sync operational between 2+ executors",
          "Shared link language with sync support installed",
          "Holochain bootstrap service",
          "Signal server for peer discovery",
        ],
        plannedWriteRates: ["10/s", "50/s", "100/s"],
        plannedMetrics: [
          "writeLatencyMs (with sync overhead)",
          "syncPropagationDelayMs",
          "writeThroughputCeiling",
          "memoryUsageUnderSync",
        ],
      },
      samples: [],
      summary: "STUB: Requires neighbourhood sync infrastructure (Holochain + link language). See scenario file for requirements.",
    };
  },
};

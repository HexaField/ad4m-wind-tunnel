/**
 * AD4M Wind Tunnel — Main Runner
 *
 * Usage:
 *   tsx src/main.ts                          # Run all scenarios against all branches
 *   tsx src/main.ts --scenario s1            # Run specific scenario
 *   tsx src/main.ts --branch dev             # Run against specific branch
 *   tsx src/main.ts --skip-build             # Skip build, use existing binaries
 *   tsx src/main.ts --executor-path <path>   # Use a pre-built executor binary
 */

import { existsSync, mkdirSync, rmSync } from "fs";
import { join } from "path";
import { execSync } from "child_process";
import { InstrumentedClient } from "./client.js";
import { buildExecutor, startExecutor, waitForHealth, stopExecutor, sleep, ExecutorConfig } from "./executor.js";
import { Scenario, ScenarioContext, ScenarioResult } from "./scenario.js";
import { s1ColdStart, s2LinkThroughput, s5QueryScaling, m1NeighbourhoodSync } from "./scenarios/index.js";
import { consoleReport, jsonReport, comparisonReport } from "./reporters.js";

const AD4M_REPO = "/Users/josh/workspaces/coasys/ad4m";
const RESULTS_DIR = join(process.cwd(), "results");
const BASE_PORT = 12100;

interface BranchConfig {
  name: string;
  transport: "rest" | "ws";
  dirName: string; // for results directory
}

const BRANCHES: BranchConfig[] = [
  { name: "dev", transport: "rest", dirName: "dev" },
  { name: "feat/sse-to-websocket", transport: "ws", dirName: "feat-sse-to-websocket" },
  { name: "feat/sparql-1.2-cleanup", transport: "rest", dirName: "feat-sparql-1.2-cleanup" },
];

const ALL_SCENARIOS: Scenario[] = [s1ColdStart, s2LinkThroughput, s5QueryScaling, m1NeighbourhoodSync];

function parseArgs(): {
  scenarios: string[];
  branches: string[];
  skipBuild: boolean;
  executorPath?: string;
} {
  const args = process.argv.slice(2);
  const result = {
    scenarios: [] as string[],
    branches: [] as string[],
    skipBuild: false,
    executorPath: undefined as string | undefined,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--scenario":
        result.scenarios.push(args[++i]);
        break;
      case "--branch":
        result.branches.push(args[++i]);
        break;
      case "--skip-build":
        result.skipBuild = true;
        break;
      case "--executor-path":
        result.executorPath = args[++i];
        break;
    }
  }

  return result;
}

async function runScenariosForBranch(
  branchConfig: BranchConfig,
  scenarios: Scenario[],
  binaryPath: string,
  port: number
): Promise<ScenarioResult[]> {
  const results: ScenarioResult[] = [];
  const dataPath = `/tmp/ad4m-wind-tunnel-data-${branchConfig.dirName}`;

  // Start executor
  const config: ExecutorConfig = {
    branch: branchConfig.name,
    port,
    dataPath,
    adminToken: "test123",
    adamRepoPath: AD4M_REPO,
    buildDir: `/tmp/ad4m-build-${branchConfig.dirName}`,
  };

  const proc = await startExecutor(binaryPath, config);

  try {
    // Wait for health
    console.log(`[runner] Waiting for executor health on port ${port}...`);
    const healthWaitMs = await waitForHealth(port, 120000);
    console.log(`[runner] Executor healthy after ${healthWaitMs.toFixed(0)}ms`);

    // For M1, start a second executor
    let proc2: any = null;
    const needsM1 = scenarios.some((s) => s.id === "m1");
    if (needsM1) {
      const dataPath2 = `/tmp/ad4m-wind-tunnel-data-${branchConfig.dirName}-2`;
      proc2 = await startExecutor(binaryPath, { ...config, port: port + 1, dataPath: dataPath2 });
      try {
        await waitForHealth(port + 1, 120000);
        console.log(`[runner] Second executor healthy on port ${port + 1}`);
      } catch (err) {
        console.log(`[runner] Second executor failed to start, M1 will be skipped`);
        stopExecutor(proc2);
        proc2 = null;
      }
    }

    // Run each scenario
    for (const scenario of scenarios) {
      console.log(`\n[runner] Running ${scenario.id}: ${scenario.name} on ${branchConfig.name}...`);

      const client = new InstrumentedClient({
        port,
        adminToken: "test123",
        transport: branchConfig.transport,
      });

      if (branchConfig.transport === "ws") {
        await client.connect();
      }

      const ctx: ScenarioContext = { client, branch: branchConfig.name, port };

      try {
        const result = await scenario.run(ctx);
        results.push(result);
        console.log(`[runner] ${scenario.id} complete: ${result.summary}`);
      } catch (err: any) {
        console.error(`[runner] ${scenario.id} CRASHED: ${err.message}`);
        results.push({
          scenario: `${scenario.id}-${scenario.name.toLowerCase().replace(/\s+/g, "-")}`,
          branch: branchConfig.name,
          startTime: Date.now(),
          endTime: Date.now(),
          durationMs: 0,
          metrics: { error: err.message },
          samples: [],
          summary: `CRASHED: ${err.message}`,
        });
      } finally {
        await client.disconnect();
      }

      // Restart executor between scenarios for clean state (except after S1 which needs cold start)
      if (scenario.id !== "s1") {
        stopExecutor(proc);
        await sleep(2000);
        // Clean data
        if (existsSync(dataPath)) rmSync(dataPath, { recursive: true, force: true });
        mkdirSync(dataPath, { recursive: true });
        const newProc = await startExecutor(binaryPath, config);
        Object.assign(proc, newProc); // hacky but works for our purposes
        await waitForHealth(port, 120000);
      }
    }

    if (proc2) stopExecutor(proc2);
  } finally {
    stopExecutor(proc);
    await sleep(1000);
  }

  return results;
}

async function main(): Promise<void> {
  const args = parseArgs();
  console.log("╔══════════════════════════════════════════════════════════════╗");
  console.log("║            AD4M WIND TUNNEL — Performance Testing           ║");
  console.log("╚══════════════════════════════════════════════════════════════╝");
  console.log(`\nConfig: ${JSON.stringify(args, null, 2)}\n`);

  // Select scenarios
  const scenarios = args.scenarios.length > 0
    ? ALL_SCENARIOS.filter((s) => args.scenarios.includes(s.id))
    : ALL_SCENARIOS;

  // Select branches
  const branches = args.branches.length > 0
    ? BRANCHES.filter((b) => args.branches.includes(b.name) || args.branches.includes(b.dirName))
    : BRANCHES;

  console.log(`Scenarios: ${scenarios.map((s) => s.id).join(", ")}`);
  console.log(`Branches: ${branches.map((b) => b.name).join(", ")}`);
  console.log("");

  // Build or locate executors
  const binaryPaths = new Map<string, string>();

  if (args.executorPath) {
    // Use provided binary for all branches
    for (const b of branches) {
      binaryPaths.set(b.name, args.executorPath);
    }
  } else if (args.skipBuild) {
    // Look for existing builds
    for (const b of branches) {
      const buildDir = `/tmp/ad4m-build-${b.dirName}`;
      const path = join(buildDir, "target", "release", "ad4m-executor");
      if (existsSync(path)) {
        binaryPaths.set(b.name, path);
      } else {
        console.error(`[runner] No binary found for ${b.name} at ${path}. Run without --skip-build first.`);
        process.exit(1);
      }
    }
  } else {
    // Build each branch
    for (const b of branches) {
      const buildDir = `/tmp/ad4m-build-${b.dirName}`;
      console.log(`\n[build] Building ${b.name}...`);
      const start = performance.now();
      try {
        const path = await buildExecutor({
          branch: b.name,
          port: BASE_PORT,
          dataPath: "",
          adminToken: "test123",
          adamRepoPath: AD4M_REPO,
          buildDir,
        });
        const elapsed = performance.now() - start;
        console.log(`[build] ${b.name} built in ${(elapsed / 1000).toFixed(0)}s`);
        binaryPaths.set(b.name, path);
      } catch (err: any) {
        console.error(`[build] FAILED to build ${b.name}: ${err.message}`);
        // Continue with other branches
      }
    }
  }

  if (binaryPaths.size === 0) {
    console.error("[runner] No executors built. Exiting.");
    process.exit(1);
  }

  // Run scenarios
  const allResults = new Map<string, ScenarioResult[]>();

  let portOffset = 0;
  for (const branchConfig of branches) {
    const binaryPath = binaryPaths.get(branchConfig.name);
    if (!binaryPath) {
      console.log(`[runner] Skipping ${branchConfig.name} (no binary)`);
      continue;
    }

    const port = BASE_PORT + portOffset * 10;
    portOffset++;

    console.log(`\n${"═".repeat(60)}`);
    console.log(`  Running scenarios against: ${branchConfig.name}`);
    console.log(`  Binary: ${binaryPath}`);
    console.log(`  Port: ${port}`);
    console.log(`${"═".repeat(60)}\n`);

    const results = await runScenariosForBranch(branchConfig, scenarios, binaryPath, port);
    allResults.set(branchConfig.dirName, results);

    // Save results
    const branchResultsDir = join(RESULTS_DIR, branchConfig.dirName);
    jsonReport(results, branchResultsDir);
    consoleReport(results);
  }

  // Generate comparison report
  if (allResults.size > 1) {
    const comparisonPath = join(RESULTS_DIR, "comparison.md");
    comparisonReport(allResults, comparisonPath);
  }

  console.log("\n[runner] All done! Results in ./results/");
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});

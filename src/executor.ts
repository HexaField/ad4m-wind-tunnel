/**
 * Executor Lifecycle Manager
 * Handles building, starting, stopping, and health-checking AD4M executor instances.
 */

import { spawn, ChildProcess, execSync } from "child_process";
import { mkdirSync, existsSync, writeFileSync, rmSync } from "fs";
import { join } from "path";

export interface ExecutorConfig {
  branch: string;
  port: number;
  dataPath: string;
  adminToken: string;
  adamRepoPath: string;
  buildDir: string; // where to clone/build
}

export interface ExecutorInstance {
  config: ExecutorConfig;
  process: ChildProcess | null;
  binaryPath: string;
  buildDurationMs: number;
  startDurationMs: number;
}

export async function buildExecutor(config: ExecutorConfig): Promise<string> {
  const { branch, buildDir, adamRepoPath } = config;

  console.log(`[executor] Building branch: ${branch} in ${buildDir}`);

  // Create shallow clone for this branch
  if (existsSync(buildDir)) {
    rmSync(buildDir, { recursive: true, force: true });
  }

  execSync(
    `git clone --depth 1 --branch ${branch} --single-branch "${adamRepoPath}" "${buildDir}"`,
    { stdio: "pipe", timeout: 60000 }
  );

  // Ensure dapp/dist placeholder exists
  const dappDir = join(buildDir, "dapp", "dist");
  mkdirSync(dappDir, { recursive: true });
  if (!existsSync(join(dappDir, "index.html"))) {
    writeFileSync(join(dappDir, "index.html"), "<!DOCTYPE html><html><body></body></html>");
  }

  // Copy CUSTOM_DENO_SNAPSHOT.bin from source repo if it exists
  const snapshotSrc = join(adamRepoPath, "CUSTOM_DENO_SNAPSHOT.bin");
  const snapshotDst = join(buildDir, "CUSTOM_DENO_SNAPSHOT.bin");
  const snapshotLink = join(buildDir, "rust-executor", "CUSTOM_DENO_SNAPSHOT.bin");
  
  if (existsSync(snapshotSrc)) {
    console.log(`[executor] Copying CUSTOM_DENO_SNAPSHOT.bin...`);
    execSync(`cp "${snapshotSrc}" "${snapshotDst}"`, { stdio: "pipe" });
    // Ensure the symlink in rust-executor points to it
    try {
      execSync(`rm -f "${snapshotLink}" && ln -s "${snapshotDst}" "${snapshotLink}"`, { stdio: "pipe" });
    } catch {}
  } else {
    // Generate Deno snapshot
    console.log(`[executor] Generating Deno snapshot for ${branch}...`);
    try {
      execSync("cargo build --release --bin generate_snapshot 2>&1", {
        cwd: buildDir,
        stdio: "pipe",
        timeout: 900000, // 15 min
      });
      execSync("cargo run --release --bin generate_snapshot 2>&1", {
        cwd: buildDir,
        stdio: "pipe",
        timeout: 300000, // 5 min
      });
    } catch (err: any) {
      console.log(`[executor] Snapshot generation failed: ${err.message?.slice(0, 200)}`);
    }
  }

  // Build the executor
  console.log(`[executor] Building ad4m-executor for ${branch}...`);
  execSync("cargo build --release --bin ad4m-executor 2>&1", {
    cwd: buildDir,
    stdio: "pipe",
    timeout: 1800000, // 30 min
  });

  const binaryPath = join(buildDir, "target", "release", "ad4m-executor");
  if (!existsSync(binaryPath)) {
    throw new Error(`Binary not found at ${binaryPath}`);
  }

  console.log(`[executor] Build complete: ${binaryPath}`);
  return binaryPath;
}

export async function startExecutor(
  binaryPath: string,
  config: ExecutorConfig
): Promise<ChildProcess> {
  // Clean data directory
  if (existsSync(config.dataPath)) {
    rmSync(config.dataPath, { recursive: true, force: true });
  }
  mkdirSync(config.dataPath, { recursive: true });

  console.log(`[executor] Starting on port ${config.port}, data: ${config.dataPath}`);

  const proc = spawn(binaryPath, [
    "run",
    "--app-data-path", config.dataPath,
    "--gql-port", String(config.port),
    "--admin-credential", config.adminToken,
    "--enable-multi-user", "true",
    "--run-dapp-server", "false",
    "--hc-use-bootstrap", "false",
    "--hc-use-mdns", "true",
    "--hc-use-proxy", "false",
  ], {
    stdio: ["pipe", "pipe", "pipe"],
    env: { ...process.env, RUST_LOG: "info" },
  });

  proc.stdout?.on("data", (d) => {
    const line = d.toString().trim();
    if (line) console.log(`[executor:${config.port}:stdout] ${line}`);
  });
  proc.stderr?.on("data", (d) => {
    const line = d.toString().trim();
    if (line) console.log(`[executor:${config.port}:stderr] ${line}`);
  });

  return proc;
}

export async function waitForHealth(
  port: number,
  timeoutMs: number = 60000
): Promise<number> {
  const start = performance.now();
  const deadline = start + timeoutMs;

  while (Date.now() < deadline) {
    try {
      const res = await fetch(`http://127.0.0.1:${port}/health`);
      if (res.ok) {
        return performance.now() - start;
      }
    } catch {}
    await sleep(500);
  }

  throw new Error(`Executor on port ${port} did not become healthy within ${timeoutMs}ms`);
}

export function stopExecutor(proc: ChildProcess): void {
  if (proc && !proc.killed) {
    proc.kill("SIGTERM");
    setTimeout(() => {
      if (!proc.killed) proc.kill("SIGKILL");
    }, 5000);
  }
}

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

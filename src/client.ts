/**
 * Instrumented AD4M Client
 * Wraps REST and WebSocket API calls with timing, error tracking, and throughput measurement.
 */

import WebSocket from "ws";

export interface TimedResult<T> {
  data: T;
  durationMs: number;
  timestamp: number;
  error?: string;
}

export interface ClientConfig {
  port: number;
  host?: string;
  adminToken: string;
  transport: "rest" | "ws";
}

export class InstrumentedClient {
  private config: ClientConfig;
  private ws: WebSocket | null = null;
  private wsReady: Promise<void> | null = null;
  private requestId = 0;
  private pendingRequests = new Map<
    string,
    { resolve: (v: any) => void; reject: (e: any) => void }
  >();

  public metrics = {
    totalRequests: 0,
    totalErrors: 0,
    totalDurationMs: 0,
    latencies: [] as number[],
  };

  constructor(config: ClientConfig) {
    this.config = { host: "127.0.0.1", ...config };
  }

  get baseUrl(): string {
    return `http://${this.config.host}:${this.config.port}`;
  }

  get wsUrl(): string {
    return `ws://${this.config.host}:${this.config.port}/api/v1/ws?token=${this.config.adminToken}`;
  }

  async connect(): Promise<void> {
    if (this.config.transport === "ws") {
      this.wsReady = new Promise((resolve, reject) => {
        this.ws = new WebSocket(this.wsUrl);
        this.ws.on("open", () => resolve());
        this.ws.on("error", (err) => reject(err));
        this.ws.on("message", (data) => {
          try {
            const msg = JSON.parse(data.toString());
            const pending = this.pendingRequests.get(msg.id);
            if (pending) {
              this.pendingRequests.delete(msg.id);
              if (msg.error) {
                pending.reject(new Error(msg.error.message || JSON.stringify(msg.error)));
              } else {
                pending.resolve(msg.result);
              }
            }
          } catch {}
        });
        this.ws.on("close", () => {
          // reject all pending
          for (const [, p] of this.pendingRequests) {
            p.reject(new Error("WebSocket closed"));
          }
          this.pendingRequests.clear();
        });
      });
      await this.wsReady;
    }
  }

  async disconnect(): Promise<void> {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  private async wsCall<T>(type: string, params: any): Promise<T> {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      throw new Error("WebSocket not connected");
    }
    const id = String(++this.requestId);
    return new Promise<T>((resolve, reject) => {
      this.pendingRequests.set(id, { resolve, reject });
      this.ws!.send(JSON.stringify({ id, type, params }));
      // Timeout after 30s
      setTimeout(() => {
        if (this.pendingRequests.has(id)) {
          this.pendingRequests.delete(id);
          reject(new Error(`WS request ${type} timed out`));
        }
      }, 30000);
    });
  }

  private async restCall<T>(
    method: string,
    path: string,
    body?: any
  ): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const opts: RequestInit = {
      method,
      headers: {
        Authorization: `Bearer ${this.config.adminToken}`,
        "Content-Type": "application/json",
      },
    };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(url, opts);
    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`HTTP ${res.status}: ${text}`);
    }
    const contentType = res.headers.get("content-type") || "";
    if (contentType.includes("application/json")) {
      return (await res.json()) as T;
    }
    return (await res.text()) as unknown as T;
  }

  async timed<T>(fn: () => Promise<T>): Promise<TimedResult<T>> {
    const start = performance.now();
    const timestamp = Date.now();
    this.metrics.totalRequests++;
    try {
      const data = await fn();
      const durationMs = performance.now() - start;
      this.metrics.totalDurationMs += durationMs;
      this.metrics.latencies.push(durationMs);
      return { data, durationMs, timestamp };
    } catch (err: any) {
      const durationMs = performance.now() - start;
      this.metrics.totalErrors++;
      this.metrics.totalDurationMs += durationMs;
      this.metrics.latencies.push(durationMs);
      return {
        data: undefined as any,
        durationMs,
        timestamp,
        error: err.message,
      };
    }
  }

  // --- High-level operations ---

  async health(): Promise<TimedResult<any>> {
    return this.timed(() => this.restCall("GET", "/health"));
  }

  async generateAgent(passphrase: string): Promise<TimedResult<any>> {
    if (this.config.transport === "ws") {
      return this.timed(() =>
        this.wsCall("agent.generate", { passphrase })
      );
    }
    return this.timed(() =>
      this.restCall("POST", "/api/v1/agent/generate", { passphrase })
    );
  }

  async createPerspective(name: string): Promise<TimedResult<any>> {
    if (this.config.transport === "ws") {
      return this.timed(() =>
        this.wsCall("perspective.create", { name })
      );
    }
    return this.timed(() =>
      this.restCall("POST", "/api/v1/perspectives", { name })
    );
  }

  async addLink(
    perspectiveUuid: string,
    source: string,
    predicate: string,
    target: string
  ): Promise<TimedResult<any>> {
    if (this.config.transport === "ws") {
      return this.timed(() =>
        this.wsCall("perspective.addLink", {
          uuid: perspectiveUuid,
          link: { source, predicate, target },
        })
      );
    }
    return this.timed(() =>
      this.restCall("POST", `/api/v1/perspectives/${perspectiveUuid}/links`, {
        source,
        predicate,
        target,
      })
    );
  }

  async queryLinks(
    perspectiveUuid: string,
    params?: { source?: string; predicate?: string; target?: string }
  ): Promise<TimedResult<any>> {
    if (this.config.transport === "ws") {
      return this.timed(() =>
        this.wsCall("perspective.queryLinks", {
          uuid: perspectiveUuid,
          query: params || {},
        })
      );
    }
    const qs = new URLSearchParams();
    if (params?.source) qs.set("source", params.source);
    if (params?.predicate) qs.set("predicate", params.predicate);
    if (params?.target) qs.set("target", params.target);
    const query = qs.toString() ? `?${qs.toString()}` : "";
    return this.timed(() =>
      this.restCall(
        "GET",
        `/api/v1/perspectives/${perspectiveUuid}/links${query}`
      )
    );
  }

  async runProlog(
    perspectiveUuid: string,
    query: string
  ): Promise<TimedResult<any>> {
    if (this.config.transport === "ws") {
      return this.timed(() =>
        this.wsCall("perspective.queryProlog", {
          uuid: perspectiveUuid,
          query,
        })
      );
    }
    return this.timed(() =>
      this.restCall("POST", `/api/v1/perspectives/${perspectiveUuid}/prolog`, {
        query,
      })
    );
  }

  resetMetrics(): void {
    this.metrics = {
      totalRequests: 0,
      totalErrors: 0,
      totalDurationMs: 0,
      latencies: [],
    };
  }

  getStats(): {
    count: number;
    errors: number;
    avgMs: number;
    p50Ms: number;
    p95Ms: number;
    p99Ms: number;
    minMs: number;
    maxMs: number;
  } {
    const sorted = [...this.metrics.latencies].sort((a, b) => a - b);
    const count = sorted.length;
    if (count === 0) {
      return { count: 0, errors: 0, avgMs: 0, p50Ms: 0, p95Ms: 0, p99Ms: 0, minMs: 0, maxMs: 0 };
    }
    return {
      count,
      errors: this.metrics.totalErrors,
      avgMs: this.metrics.totalDurationMs / count,
      p50Ms: sorted[Math.floor(count * 0.5)],
      p95Ms: sorted[Math.floor(count * 0.95)],
      p99Ms: sorted[Math.floor(count * 0.99)],
      minMs: sorted[0],
      maxMs: sorted[count - 1],
    };
  }
}

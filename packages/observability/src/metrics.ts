import {
  type Counter,
  type Histogram,
  metrics,
  type ObservableGauge,
  type UpDownCounter,
} from "@opentelemetry/api";

/**
 * Create a counter for a given bounded context.
 * Counters only increase.
 *
 * @example
 *   const proposalsSubmitted = createCounter("governance", "proposals.submitted.total", {
 *     description: "Total number of proposals submitted",
 *   });
 *   proposalsSubmitted.add(1, { "proposal.type": "constitutional" });
 */
export function createCounter(
  context: string,
  name: string,
  options?: { description?: string; unit?: string },
): Counter {
  return metrics
    .getMeter(`ardtire.${context}`)
    .createCounter(`ardtire.${context}.${name}`, options);
}

/**
 * Create an up-down counter (can increase or decrease).
 * Suitable for gauges that track active counts (connections, queue depth).
 */
export function createUpDownCounter(
  context: string,
  name: string,
  options?: { description?: string; unit?: string },
): UpDownCounter {
  return metrics
    .getMeter(`ardtire.${context}`)
    .createUpDownCounter(`ardtire.${context}.${name}`, options);
}

/**
 * Create a histogram for measuring distributions (latency, payload sizes).
 *
 * @example
 *   const requestDuration = createHistogram("api", "http.request.duration", {
 *     description: "HTTP request duration",
 *     unit: "ms",
 *   });
 *   requestDuration.record(elapsed, { "http.route": route, "http.status_code": status });
 */
export function createHistogram(
  context: string,
  name: string,
  options?: { description?: string; unit?: string },
): Histogram {
  return metrics
    .getMeter(`ardtire.${context}`)
    .createHistogram(`ardtire.${context}.${name}`, options);
}

/**
 * Create an observable gauge for values that are sampled at collection time.
 * Useful for memory usage, pool sizes, or external readings.
 */
export function createObservableGauge(
  context: string,
  name: string,
  callback: (value: (v: number, attrs?: Record<string, string>) => void) => void,
  options?: { description?: string; unit?: string },
): ObservableGauge {
  const meter = metrics.getMeter(`ardtire.${context}`);
  const gauge = meter.createObservableGauge(`ardtire.${context}.${name}`, options);
  gauge.addCallback((result) => {
    callback((v, attrs) => result.observe(v, attrs));
  });
  return gauge;
}

// ── Platform-wide standard metrics ───────────────────────────────────────────
// Import and use these directly rather than creating new metrics with the same
// semantic meaning in individual packages.

export const httpRequestDuration = createHistogram("api", "http.request.duration", {
  description: "HTTP request duration in milliseconds",
  unit: "ms",
});

export const httpRequestCount = createCounter("api", "http.requests.total", {
  description: "Total HTTP requests handled",
});

export const governanceProposalsTotal = createCounter("governance", "proposals.total", {
  description: "Total governance proposals by status",
});

export const governanceVotesCastTotal = createCounter("governance", "votes.cast.total", {
  description: "Total governance votes cast",
});

export const auditLogEntriesTotal = createCounter("audit", "log.entries.total", {
  description: "Total audit log entries emitted",
});

export const authFailuresTotal = createCounter("auth", "failures.total", {
  description: "Total authentication failures by reason",
});

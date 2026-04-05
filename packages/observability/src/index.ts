/**
 * @ardtire/observability
 *
 * Public API surface for the Ardtire observability package.
 *
 * SDK INITIALISATION NOTE:
 * The OTel SDK must be started before any instrumented libraries are loaded.
 * Import the SDK entry point separately as the very first line of each app:
 *
 *   import "@ardtire/observability/sdk";
 *
 * This barrel export does NOT re-export the SDK initialisation to avoid
 * accidental import ordering issues.
 */

export { createLogger } from "./logger.js";
export type { Logger } from "./logger.js";

export {
  createCounter,
  createHistogram,
  createObservableGauge,
  createUpDownCounter,
  // Platform-wide standard metrics
  auditLogEntriesTotal,
  authFailuresTotal,
  governanceProposalsTotal,
  governanceVotesCastTotal,
  httpRequestCount,
  httpRequestDuration,
} from "./metrics.js";

export {
  context,
  getActiveSpanId,
  getActiveTraceId,
  getTracer,
  rootTracer,
  SpanStatusCode,
  trace,
  withSpan,
} from "./tracer.js";
export type { Span, Tracer } from "./tracer.js";

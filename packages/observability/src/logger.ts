/**
 * Structured JSON logger with automatic OpenTelemetry trace context injection.
 *
 * Every log record includes the active trace ID and span ID when a span is
 * active, enabling correlation between logs and traces in any backend that
 * supports structured log ingestion (Loki, Cloud Logging, Datadog, etc.).
 *
 * IMPORTANT: This logger does not replace or wrap a third-party logger — it
 * is the canonical logging interface for the platform. Do not use console.log
 * in application code.
 */
import { getActiveSpanId, getActiveTraceId } from "./tracer.js";

type LogLevel = "error" | "warn" | "info" | "debug";

interface LogRecord {
  level: LogLevel;
  message: string;
  timestamp: string;
  service?: string;
  traceId?: string;
  spanId?: string;
  correlationId?: string;
  [key: string]: unknown;
}

const LEVEL_RANKS: Record<LogLevel, number> = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
};

function getConfiguredLevel(): LogLevel {
  const raw = (process.env["LOG_LEVEL"] ?? "info").toLowerCase();
  if (raw === "error" || raw === "warn" || raw === "info" || raw === "debug") {
    return raw;
  }
  return "info";
}

function shouldLog(level: LogLevel): boolean {
  return LEVEL_RANKS[level] <= LEVEL_RANKS[getConfiguredLevel()];
}

function write(
  level: LogLevel,
  message: string,
  fields?: Record<string, unknown>,
  service?: string,
): void {
  if (!shouldLog(level)) return;

  const record: LogRecord = {
    level,
    message,
    timestamp: new Date().toISOString(),
    ...(service ? { service } : {}),
    traceId: getActiveTraceId(),
    spanId: getActiveSpanId(),
    ...fields,
  };

  // Remove undefined fields for clean JSON output.
  const clean = Object.fromEntries(
    Object.entries(record).filter(([, v]) => v !== undefined),
  );

  const line = JSON.stringify(clean);

  if (level === "error") {
    process.stderr.write(line + "\n");
  } else {
    process.stdout.write(line + "\n");
  }
}

export interface Logger {
  error(message: string, fields?: Record<string, unknown>): void;
  warn(message: string, fields?: Record<string, unknown>): void;
  info(message: string, fields?: Record<string, unknown>): void;
  debug(message: string, fields?: Record<string, unknown>): void;
  child(bindings: Record<string, unknown>): Logger;
}

/**
 * Create a logger bound to a service name.
 * Pass additional fields via `child()` to create scoped loggers for modules
 * or request handlers.
 *
 * @example
 *   const log = createLogger("gov-api");
 *   const requestLog = log.child({ correlationId, route: "/proposals" });
 *   requestLog.info("Proposal submitted", { proposalId });
 */
export function createLogger(service: string, bindings?: Record<string, unknown>): Logger {
  function makeLogger(extraBindings?: Record<string, unknown>): Logger {
    const merged = { ...bindings, ...extraBindings };

    return {
      error: (msg, fields) => write("error", msg, { ...merged, ...fields }, service),
      warn: (msg, fields) => write("warn", msg, { ...merged, ...fields }, service),
      info: (msg, fields) => write("info", msg, { ...merged, ...fields }, service),
      debug: (msg, fields) => write("debug", msg, { ...merged, ...fields }, service),
      child: (newBindings) => makeLogger({ ...merged, ...newBindings }),
    };
  }

  return makeLogger();
}

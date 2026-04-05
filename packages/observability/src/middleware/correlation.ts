/**
 * Correlation ID middleware for Hono.
 *
 * Generates or forwards a correlation ID on every request, sets it as
 * an attribute on the active OTel span, injects it into the response
 * header, and makes it available via `c.get("correlationId")`.
 *
 * This middleware must be registered AFTER otelMiddleware so that a span
 * is already active when correlation ID injection occurs.
 *
 * Usage:
 *   app.use("*", otelMiddleware({ service: "gov-api" }));
 *   app.use("*", correlationMiddleware());
 */
import { trace } from "@opentelemetry/api";
import { randomUUID } from "node:crypto";

const CORRELATION_HEADER = "x-correlation-id";

type HonoMiddlewareNext = () => Promise<void>;

interface HonoContext {
  req: { header(name: string): string | undefined };
  set(key: string, value: unknown): void;
  header(name: string, value: string): void;
}

/**
 * Hono middleware factory for correlation ID propagation.
 */
export function correlationMiddleware(): (
  c: HonoContext,
  next: HonoMiddlewareNext,
) => Promise<void> {
  return async (c, next) => {
    const correlationId = c.req.header(CORRELATION_HEADER) ?? randomUUID();

    // Inject into the active OTel span as a custom attribute.
    const span = trace.getActiveSpan();
    span?.setAttribute("ardtire.correlation_id", correlationId);

    // Make available to downstream handlers and middleware.
    c.set("correlationId", correlationId);

    // Echo back in response headers for client-side tracing.
    c.header(CORRELATION_HEADER, correlationId);

    await next();
  };
}

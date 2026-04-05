import { context, type Span, SpanStatusCode, trace, type Tracer } from "@opentelemetry/api";

const TRACER_NAME = "@ardtire/observability";

/**
 * Get a named tracer for a bounded context or module.
 *
 * @example
 *   const tracer = getTracer("governance");
 *   const span = tracer.startSpan("submitProposal");
 */
export function getTracer(name: string, version?: string): Tracer {
  return trace.getTracer(`ardtire.${name}`, version);
}

/**
 * Execute `fn` within a new span, recording exceptions and setting the span
 * status automatically.
 *
 * @example
 *   const result = await withSpan("governance", "submitProposal", async (span) => {
 *     span.setAttribute("proposal.id", proposalId);
 *     return await proposalService.submit(input);
 *   });
 */
export async function withSpan<T>(
  tracerName: string,
  spanName: string,
  fn: (span: Span) => Promise<T>,
  attributes?: Record<string, string | number | boolean>,
): Promise<T> {
  const tracer = getTracer(tracerName);
  return tracer.startActiveSpan(spanName, async (span) => {
    if (attributes) {
      span.setAttributes(attributes);
    }
    try {
      const result = await fn(span);
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (err: unknown) {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: err instanceof Error ? err.message : String(err),
      });
      span.recordException(err instanceof Error ? err : new Error(String(err)));
      throw err;
    } finally {
      span.end();
    }
  });
}

/**
 * Return the trace ID from the currently active span, or undefined if there
 * is no active span. Useful for injecting trace IDs into log records.
 */
export function getActiveTraceId(): string | undefined {
  const span = trace.getActiveSpan();
  if (!span) return undefined;
  const { traceId } = span.spanContext();
  return traceId === "00000000000000000000000000000000" ? undefined : traceId;
}

/**
 * Return the span ID from the currently active span, or undefined.
 */
export function getActiveSpanId(): string | undefined {
  const span = trace.getActiveSpan();
  if (!span) return undefined;
  const { spanId } = span.spanContext();
  return spanId === "0000000000000000" ? undefined : spanId;
}

/**
 * Low-level tracer instance for custom instrumentation.
 * Prefer `withSpan` for most use cases.
 */
export const rootTracer = trace.getTracer(TRACER_NAME);

export { context, SpanStatusCode, trace };
export type { Span, Tracer };

/**
 * Hono middleware for OpenTelemetry HTTP instrumentation.
 *
 * Responsibilities:
 *   1. Extract the W3C `traceparent` context from inbound request headers.
 *   2. Start a server span for each request.
 *   3. Record standard HTTP semantic convention attributes on the span.
 *   4. Set the span status based on the HTTP response status code.
 *   5. Propagate trace context to outbound response headers.
 *
 * Usage (in your Hono app entry point, AFTER importing the SDK):
 *
 *   import "@ardtire/observability/sdk";  // must be first
 *   import { otelMiddleware } from "@ardtire/observability/middleware/hono";
 *
 *   const app = new Hono();
 *   app.use("*", otelMiddleware({ service: "gov-api" }));
 */
import { context, propagation, SpanKind, SpanStatusCode, trace } from "@opentelemetry/api";
import {
  SEMATTRS_HTTP_METHOD,
  SEMATTRS_HTTP_ROUTE,
  SEMATTRS_HTTP_STATUS_CODE,
  SEMATTRS_HTTP_TARGET,
  SEMATTRS_HTTP_URL,
  SEMATTRS_NET_HOST_NAME,
} from "@opentelemetry/semantic-conventions";

type HonoMiddlewareNext = () => Promise<void>;

interface HonoContext {
  req: {
    method: string;
    url: string;
    path: string;
    routePath?: string;
    raw: { headers: Headers };
    header(name: string): string | undefined;
  };
  res: { status: number };
  set(key: string, value: unknown): void;
  get(key: string): unknown;
  header(name: string, value: string): void;
}

interface OtelMiddlewareOptions {
  /** Service name used as the tracer scope. */
  service: string;
}

/**
 * Hono middleware factory for OTel HTTP instrumentation.
 */
export function otelMiddleware(
  options: OtelMiddlewareOptions,
): (c: HonoContext, next: HonoMiddlewareNext) => Promise<void> {
  const tracer = trace.getTracer(`ardtire.${options.service}`);

  return async (c, next) => {
    const url = new URL(c.req.url);

    // Extract W3C trace context from inbound headers.
    const carrier: Record<string, string> = {};
    c.req.raw.headers.forEach((value, key) => {
      carrier[key] = value;
    });
    const parentContext = propagation.extract(context.active(), carrier);

    const spanName = `${c.req.method} ${c.req.routePath ?? c.req.path}`;

    await context.with(parentContext, async () => {
      const span = tracer.startSpan(
        spanName,
        {
          kind: SpanKind.SERVER,
          attributes: {
            [SEMATTRS_HTTP_METHOD]: c.req.method,
            [SEMATTRS_HTTP_URL]: c.req.url,
            [SEMATTRS_HTTP_TARGET]: url.pathname + url.search,
            [SEMATTRS_NET_HOST_NAME]: url.hostname,
          },
        },
        parentContext,
      );

      await context.with(trace.setSpan(parentContext, span), async () => {
        try {
          await next();

          const status = c.res.status;
          span.setAttribute(SEMATTRS_HTTP_STATUS_CODE, status);

          if (c.req.routePath) {
            span.setAttribute(SEMATTRS_HTTP_ROUTE, c.req.routePath);
          }

          if (status >= 500) {
            span.setStatus({ code: SpanStatusCode.ERROR, message: `HTTP ${status}` });
          } else {
            span.setStatus({ code: SpanStatusCode.OK });
          }
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
    });
  };
}

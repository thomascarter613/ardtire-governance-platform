#!/usr/bin/env bash
# =============================================================================
# scaffold-addendum.sh
# Run this from INSIDE the ardtire-governance-platform directory, after
# scaffold.sh has been executed.
#
# Adds:
#   1. .devcontainer/  — reproducible dev environment via VS Code Dev Containers
#   2. packages/observability/  — unified OTel SDK, tracer, metrics, and Hono middleware
#   3. typespec/  — TypeSpec schema-driven OpenAPI generation (replaces hand-written YAML)
#   4. .github/workflows/infra-policy.yml + .checkov.yaml  — Checkov policy-as-code in CI
#
# Also updates (full replacement):
#   - turbo.json  — adds typespec compile task
#   - package.json  — adds TypeSpec + updated OTel devDependencies
#   - justfile  — adds typespec-compile, typespec-validate, and policy-check tasks
# =============================================================================
set -euo pipefail

if [[ ! -f "package.json" ]] || [[ ! -f "turbo.json" ]]; then
  echo "ERROR: Run this script from inside ardtire-governance-platform/" >&2
  exit 1
fi

# ============================================================
# DIRECTORIES
# ============================================================
mkdir -p \
  .devcontainer \
  packages/observability/src/middleware \
  typespec \
  infra \
  .github/workflows

touch infra/.gitkeep

# =============================================================================
# 1. DEV CONTAINERS
# =============================================================================

# ============================================================
# .devcontainer/devcontainer.json
# ============================================================
cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "Ardtire Governance Platform",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-docker:1": {
      "moby": true,
      "dockerDashComposeVersion": "v2"
    },
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "postStartCommand": "mise install",
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached,readonly"
  ],
  "remoteUser": "vscode",
  "remoteEnv": {
    "NODE_ENV": "development"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "biomejs.biome",
        "EditorConfig.EditorConfig",
        "eamodio.gitlens",
        "github.vscode-github-actions",
        "github.vscode-pull-request-github",
        "ms-azuretools.vscode-docker",
        "ms-vscode.vscode-typescript-next",
        "redhat.vscode-yaml",
        "streetsidesoftware.code-spell-checker",
        "vitest.explorer",
        "yoavbls.pretty-ts-errors",
        "mikestead.dotenv",
        "Prisma.prisma",
        "tamasfe.even-better-toml",
        "ms-vscode.azure-account",
        "mindaro.mindaro"
      ],
      "settings": {
        "editor.defaultFormatter": "biomejs.biome",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "quickfix.biome": "explicit",
          "source.organizeImports.biome": "explicit"
        },
        "typescript.tsdk": "node_modules/typescript/lib",
        "typescript.enablePromptUseWorkspaceTsdk": true,
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  },
  "forwardPorts": [3001, 5432, 7700, 8025, 8080],
  "portsAttributes": {
    "3001": { "label": "Governance API", "onAutoForward": "notify" },
    "5432": { "label": "PostgreSQL", "onAutoForward": "silent" },
    "7700": { "label": "Meilisearch", "onAutoForward": "silent" },
    "8025": { "label": "Mailpit UI", "onAutoForward": "notify" },
    "8080": { "label": "Keycloak", "onAutoForward": "notify" }
  }
}
EOF

# ============================================================
# .devcontainer/post-create.sh
# ============================================================
cat > .devcontainer/post-create.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [devcontainer] Starting post-create setup..."

# ── System packages ───────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  curl \
  git \
  gnupg \
  jq \
  postgresql-client \
  unzip \
  wget \
  ca-certificates

# ── mise ──────────────────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing mise..."
curl -sSf https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
echo 'eval "$(mise activate bash)"' >> "$HOME/.bashrc"

# ── just ──────────────────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing just..."
curl --proto '=https' --tlsv1.2 -sSf \
  https://just.systems/install.sh | bash -s -- --to /usr/local/bin
chmod +x /usr/local/bin/just

# ── Checkov ───────────────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing Checkov..."
sudo pip3 install checkov --break-system-packages 2>/dev/null || \
  pip3 install --user checkov

# ── TypeSpec CLI ──────────────────────────────────────────────────────────────
echo "==> [devcontainer] TypeSpec CLI installed via workspace pnpm devDependencies."

# ── Runtime via mise ─────────────────────────────────────────────────────────
echo "==> [devcontainer] Installing Node + pnpm via mise..."
mise install

# ── Workspace dependencies ───────────────────────────────────────────────────
echo "==> [devcontainer] Installing pnpm workspace dependencies..."
pnpm install

# ── Copy env example ─────────────────────────────────────────────────────────
if [[ ! -f ".env" ]]; then
  cp .env.example .env
  echo "==> [devcontainer] .env created from .env.example — review and fill in values."
fi

echo ""
echo "==> [devcontainer] Setup complete. Run 'just doctor' to verify your environment."
echo "==> [devcontainer] Run 'just compose-up && just db-migrate && just db-seed' to start local services."
EOF
chmod +x .devcontainer/post-create.sh

# =============================================================================
# 2. PACKAGES/OBSERVABILITY
# =============================================================================

# ============================================================
# packages/observability/package.json
# ============================================================
cat > packages/observability/package.json << 'EOF'
{
  "name": "@ardtire/observability",
  "version": "0.0.0",
  "private": true,
  "description": "Unified OpenTelemetry SDK initialization, tracer, metrics, structured logger, and Hono middleware for the Ardtire platform.",
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "types": "./dist/index.d.ts"
    },
    "./sdk": {
      "import": "./dist/sdk.js",
      "types": "./dist/sdk.d.ts"
    },
    "./middleware/hono": {
      "import": "./dist/middleware/hono.js",
      "types": "./dist/middleware/hono.d.ts"
    },
    "./middleware/correlation": {
      "import": "./dist/middleware/correlation.js",
      "types": "./dist/middleware/correlation.d.ts"
    }
  },
  "scripts": {
    "build": "tsc --project tsconfig.json",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@opentelemetry/api": "1.9.0",
    "@opentelemetry/context-async-hooks": "1.30.1",
    "@opentelemetry/core": "1.30.1",
    "@opentelemetry/exporter-metrics-otlp-http": "0.57.1",
    "@opentelemetry/exporter-trace-otlp-http": "0.57.1",
    "@opentelemetry/instrumentation": "0.57.1",
    "@opentelemetry/instrumentation-http": "0.57.1",
    "@opentelemetry/resources": "1.30.1",
    "@opentelemetry/sdk-metrics": "1.30.1",
    "@opentelemetry/sdk-node": "0.57.1",
    "@opentelemetry/sdk-trace-node": "1.30.1",
    "@opentelemetry/semantic-conventions": "1.28.0"
  },
  "devDependencies": {
    "@ardtire/tsconfig": "workspace:*",
    "@ardtire/vitest-config": "workspace:*",
    "typescript": "5.8.3",
    "vitest": "3.1.1"
  },
  "license": "UNLICENSED"
}
EOF

# ============================================================
# packages/observability/tsconfig.json
# ============================================================
cat > packages/observability/tsconfig.json << 'EOF'
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "extends": "@ardtire/tsconfig/base.json",
  "compilerOptions": {
    "rootDir": "src",
    "outDir": "dist",
    "noEmit": false
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

# ============================================================
# packages/observability/vitest.config.ts
# ============================================================
cat > packages/observability/vitest.config.ts << 'EOF'
import { baseConfig } from "@ardtire/vitest-config/base";
import { defineConfig, mergeConfig } from "vitest/config";

export default mergeConfig(
  baseConfig,
  defineConfig({
    test: {
      name: "observability",
    },
  }),
);
EOF

# ============================================================
# packages/observability/src/sdk.ts
# ============================================================
# This file MUST be the first import in any app entry point.
# It registers the OTel SDK before any instrumented libraries are loaded.
cat > packages/observability/src/sdk.ts << 'EOF'
/**
 * OpenTelemetry SDK initialisation.
 *
 * CRITICAL: This module must be imported BEFORE any other application module.
 * In Hono/Node apps, import it as the very first line of your entry point:
 *
 *   import "@ardtire/observability/sdk";
 *   import { Hono } from "hono";
 *   // ...
 *
 * Or register via the --import flag at process startup:
 *   node --import @ardtire/observability/sdk dist/main.js
 */
import { AsyncLocalStorageContextManager } from "@opentelemetry/context-async-hooks";
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-http";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { registerInstrumentations } from "@opentelemetry/instrumentation";
import { HttpInstrumentation } from "@opentelemetry/instrumentation-http";
import {
  detectResourcesSync,
  envDetectorSync,
  hostDetectorSync,
  processDetectorSync,
  Resource,
} from "@opentelemetry/resources";
import { NodeSDK } from "@opentelemetry/sdk-node";
import {
  PeriodicExportingMetricReader,
} from "@opentelemetry/sdk-metrics";
import {
  SEMRESATTRS_DEPLOYMENT_ENVIRONMENT,
  SEMRESATTRS_SERVICE_NAME,
  SEMRESATTRS_SERVICE_VERSION,
} from "@opentelemetry/semantic-conventions";

const serviceName = process.env["OTEL_SERVICE_NAME"] ?? "ardtire-unknown-service";
const serviceVersion = process.env["OTEL_SERVICE_VERSION"] ?? "0.0.0";
const deploymentEnv = process.env["NODE_ENV"] ?? "development";
const otelEnabled = process.env["OTEL_ENABLED"] !== "false";
const otlpEndpoint = process.env["OTEL_EXPORTER_OTLP_ENDPOINT"] ?? "http://localhost:4318";

const detectedResource = detectResourcesSync({
  detectors: [envDetectorSync, hostDetectorSync, processDetectorSync],
});

const serviceResource = new Resource({
  [SEMRESATTRS_SERVICE_NAME]: serviceName,
  [SEMRESATTRS_SERVICE_VERSION]: serviceVersion,
  [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: deploymentEnv,
});

const resource = serviceResource.merge(detectedResource);

let sdk: NodeSDK | undefined;

if (otelEnabled) {
  sdk = new NodeSDK({
    resource,
    traceExporter: new OTLPTraceExporter({
      url: `${otlpEndpoint}/v1/traces`,
    }),
    metricReader: new PeriodicExportingMetricReader({
      exporter: new OTLPMetricExporter({
        url: `${otlpEndpoint}/v1/metrics`,
      }),
      exportIntervalMillis: 30_000,
    }),
    contextManager: new AsyncLocalStorageContextManager(),
    instrumentations: [
      new HttpInstrumentation({
        ignoreIncomingRequestHook: (req) => {
          // Do not trace health check endpoints — they are high-frequency and low-value.
          return req.url === "/health" || req.url === "/health/ready";
        },
      }),
    ],
  });

  sdk.start();

  process.on("SIGTERM", () => {
    sdk
      ?.shutdown()
      .then(() => {
        process.exit(0);
      })
      .catch((err: unknown) => {
        console.error("[otel] SDK shutdown error:", err);
        process.exit(1);
      });
  });
}

registerInstrumentations({
  instrumentations: [],
});

export { sdk };
EOF

# ============================================================
# packages/observability/src/tracer.ts
# ============================================================
cat > packages/observability/src/tracer.ts << 'EOF'
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
EOF

# ============================================================
# packages/observability/src/metrics.ts
# ============================================================
cat > packages/observability/src/metrics.ts << 'EOF'
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
EOF

# ============================================================
# packages/observability/src/logger.ts
# ============================================================
cat > packages/observability/src/logger.ts << 'EOF'
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
EOF

# ============================================================
# packages/observability/src/middleware/hono.ts
# ============================================================
cat > packages/observability/src/middleware/hono.ts << 'EOF'
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
EOF

# ============================================================
# packages/observability/src/middleware/correlation.ts
# ============================================================
cat > packages/observability/src/middleware/correlation.ts << 'EOF'
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
EOF

# ============================================================
# packages/observability/src/index.ts
# ============================================================
cat > packages/observability/src/index.ts << 'EOF'
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
EOF

# =============================================================================
# 3. TYPESPEC — SCHEMA-DRIVEN API
# =============================================================================

# ============================================================
# tsp-config.yaml
# ============================================================
cat > tsp-config.yaml << 'EOF'
# TypeSpec compiler configuration.
# Running `tsp compile typespec/` generates docs/api/openapi.yaml.
# The generated file is the canonical OpenAPI spec — do not edit it by hand.
#
# Install: pnpm add -D -w @typespec/compiler @typespec/http @typespec/rest @typespec/openapi3
# Compile: pnpm tsp compile typespec/
# Watch:   pnpm tsp compile typespec/ --watch

emit:
  - "@typespec/openapi3"

options:
  "@typespec/openapi3":
    output-file: "docs/api/openapi.yaml"
    file-type: yaml
EOF

# ============================================================
# typespec/common.tsp
# ============================================================
cat > typespec/common.tsp << 'EOF'
import "@typespec/http";
import "@typespec/rest";

using TypeSpec.Http;
using TypeSpec.Rest;

namespace Ardtire.Common;

/**
 * Standard error response returned by all API endpoints on failure.
 */
model ErrorResponse {
  /** Machine-readable error code. */
  code: string;

  /** Human-readable error description. */
  message: string;

  /** Optional structured detail payload for client-side handling. */
  details?: Record<unknown>;
}

/**
 * Pagination metadata included in all paginated list responses.
 */
model PaginationMeta {
  page: int32;
  pageSize: int32;
  total: int32;
  totalPages: int32;
}

/**
 * Standard paginated list wrapper.
 */
model PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
}

/**
 * Query parameters for paginated endpoints.
 */
model PaginationQuery {
  @query page?: int32 = 1;
  @query pageSize?: int32 = 25;
}

/**
 * Canonical timestamp pair included on all auditable resources.
 */
model Timestamps {
  @visibility("read") createdAt: utcDateTime;
  @visibility("read") updatedAt: utcDateTime;
}
EOF

# ============================================================
# typespec/health.tsp
# ============================================================
cat > typespec/health.tsp << 'EOF'
import "@typespec/http";
import "@typespec/rest";

using TypeSpec.Http;
using TypeSpec.Rest;

namespace Ardtire.Health;

enum ServiceStatus {
  ok,
  degraded,
  unhealthy,
}

model HealthResponse {
  status: ServiceStatus;
  timestamp: utcDateTime;
  version: string;
  services?: Record<ServiceStatus>;
}

@route("/health")
@tag("health")
interface HealthEndpoints {
  /**
   * Liveness check. Returns 200 if the process is running.
   * Does not check downstream dependencies.
   */
  @get
  @summary("Liveness check")
  @useAuth(NoAuth)
  liveness(): {
    @statusCode statusCode: 200;
    @body body: HealthResponse;
  };

  /**
   * Readiness check. Returns 200 only when all dependencies are healthy.
   * Used by load balancers and orchestrators to gate traffic.
   */
  @get
  @route("ready")
  @summary("Readiness check")
  @useAuth(NoAuth)
  readiness():
    | {
        @statusCode statusCode: 200;
        @body body: HealthResponse;
      }
    | {
        @statusCode statusCode: 503;
        @body body: HealthResponse;
      };
}
EOF

# ============================================================
# typespec/members.tsp
# ============================================================
cat > typespec/members.tsp << 'EOF'
import "@typespec/http";
import "@typespec/rest";
import "./common.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using Ardtire.Common;

namespace Ardtire.Members;

enum MemberTier {
  ASSOCIATE_MEMBER,
  FULL_MEMBER,
}

enum MemberStanding {
  PENDING,
  ACTIVE,
  SUSPENDED,
  EXPELLED,
}

/**
 * A registered member of the Ardtire Society.
 */
model Member {
  @visibility("read") id: string;
  displayName: string;
  tier: MemberTier;
  standing: MemberStanding;
  ...Timestamps;
}

model CreateMemberInput {
  displayName: string;
  tier: MemberTier;
}

model UpdateMemberStandingInput {
  standing: MemberStanding;
  reason: string;
}

@route("/members")
@tag("members")
interface MemberEndpoints {
  /**
   * List all members (paginated).
   * Requires Officer role or higher.
   */
  @get
  @summary("List members")
  list(...PaginationQuery): {
    @statusCode statusCode: 200;
    @body body: PaginatedResponse<Member>;
  };

  /**
   * Get a single member by ID.
   */
  @get
  @route("{id}")
  @summary("Get member")
  get(@path id: string):
    | {
        @statusCode statusCode: 200;
        @body body: Member;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      };

  /**
   * Register a new member.
   */
  @post
  @summary("Create member")
  create(@body body: CreateMemberInput): {
    @statusCode statusCode: 201;
    @body body: Member;
  };

  /**
   * Update a member's standing (suspend, reinstate, or expel).
   * Requires Officer role or higher. Audit-logged.
   */
  @patch
  @route("{id}/standing")
  @summary("Update member standing")
  updateStanding(
    @path id: string,
    @body body: UpdateMemberStandingInput,
  ):
    | {
        @statusCode statusCode: 200;
        @body body: Member;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 422;
        @body body: ErrorResponse;
      };
}
EOF

# ============================================================
# typespec/governance.tsp
# ============================================================
cat > typespec/governance.tsp << 'EOF'
import "@typespec/http";
import "@typespec/rest";
import "./common.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using Ardtire.Common;

namespace Ardtire.Governance;

enum ProposalStatus {
  DRAFT,
  SUBMITTED,
  UNDER_DELIBERATION,
  VOTING,
  RATIFICATION_PENDING,
  RATIFIED,
  REJECTED,
  WITHDRAWN,
}

enum VoteChoice {
  AYE,
  NAY,
  ABSTAIN,
}

/**
 * A formal governance proposal. Initiates the governance lifecycle.
 */
model Proposal {
  @visibility("read") id: string;
  title: string;
  summary: string;
  body: string;
  status: ProposalStatus;

  /** The ID of the rule version active at submission time. Immutable after submission. */
  @visibility("read") ruleVersionId: string;

  /** The member ID of the proposer. */
  @visibility("read") submitterId: string;

  deliberationOpensAt?: utcDateTime;
  deliberationClosesAt?: utcDateTime;
  votingOpensAt?: utcDateTime;
  votingClosesAt?: utcDateTime;

  ...Timestamps;
}

model SubmitProposalInput {
  title: string;
  summary: string;
  body: string;
}

model CastVoteInput {
  choice: VoteChoice;
}

model VoteRecord {
  @visibility("read") id: string;
  @visibility("read") proposalId: string;
  @visibility("read") voterId: string;
  choice: VoteChoice;
  @visibility("read") castAt: utcDateTime;
}

model VoteResult {
  @visibility("read") proposalId: string;
  ayeCount: int32;
  nayCount: int32;
  abstainCount: int32;
  totalEligible: int32;
  quorumMet: boolean;
  passed: boolean;
  @visibility("read") computedAt: utcDateTime;
}

@route("/governance/proposals")
@tag("proposals")
interface ProposalEndpoints {
  /**
   * List governance proposals (paginated).
   */
  @get
  @summary("List proposals")
  list(...PaginationQuery): {
    @statusCode statusCode: 200;
    @body body: PaginatedResponse<Proposal>;
  };

  /**
   * Get a single proposal by ID.
   */
  @get
  @route("{id}")
  @summary("Get proposal")
  get(@path id: string):
    | {
        @statusCode statusCode: 200;
        @body body: Proposal;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      };

  /**
   * Submit a new governance proposal.
   * Requires Full Member standing or Officer role.
   */
  @post
  @summary("Submit proposal")
  submit(@body body: SubmitProposalInput): {
    @statusCode statusCode: 201;
    @body body: Proposal;
  };

  /**
   * Cast a vote on a proposal.
   * The requesting member must be eligible (Full Member, ACTIVE standing,
   * enrolled before vote-open time). Each eligible member may vote exactly once.
   */
  @post
  @route("{id}/votes")
  @summary("Cast vote")
  castVote(
    @path id: string,
    @body body: CastVoteInput,
  ):
    | {
        @statusCode statusCode: 201;
        @body body: VoteRecord;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 409;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 422;
        @body body: ErrorResponse;
      };

  /**
   * Get the computed vote result for a proposal.
   * Only available after voting has closed.
   */
  @get
  @route("{id}/result")
  @summary("Get vote result")
  getResult(@path id: string):
    | {
        @statusCode statusCode: 200;
        @body body: VoteResult;
      }
    | {
        @statusCode statusCode: 404;
        @body body: ErrorResponse;
      }
    | {
        @statusCode statusCode: 409;
        @body body: ErrorResponse;
      };
}
EOF

# ============================================================
# typespec/main.tsp
# ============================================================
cat > typespec/main.tsp << 'EOF'
/**
 * Ardtire Governance API — TypeSpec root.
 *
 * This file is the TypeSpec compiler entry point.
 * Running `tsp compile typespec/` regenerates docs/api/openapi.yaml.
 *
 * DO NOT manually edit docs/api/openapi.yaml — it is a generated artifact.
 * All API changes must originate here as TypeSpec definitions.
 *
 * Compile:  pnpm tsp compile typespec/
 * Watch:    pnpm tsp compile typespec/ --watch
 * Validate: pnpm tsp compile typespec/ --no-emit
 */
import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

import "./common.tsp";
import "./health.tsp";
import "./members.tsp";
import "./governance.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;

/**
 * The Ardtire Governance API.
 *
 * The canonical governance API for the Ardtire Society. This API is the single
 * authoritative source of truth for all governance state. All governance outcomes,
 * membership records, and audit events originate here.
 *
 * When this API and any other system disagree on governance state, this API is correct.
 */
@service({
  title: "Ardtire Governance API",
})
@info({
  version: "0.1.0",
  contact: {
    name: "Thomas J. Carter",
    email: "thomas.carter@appliedinnovationcorp.com",
    url: "https://www.ardtiresociety.org",
  },
  license: {
    name: "Proprietary",
    identifier: "LicenseRef-Proprietary",
  },
})
@server("https://api.ardtiresociety.org", "Production")
@server("https://staging-api.ardtiresociety.org", "Staging")
@server("http://localhost:3001", "Local development")
@useAuth(BearerAuth)
namespace ArdtireGovernanceApi;
EOF

# ============================================================
# docs/api/openapi.yaml — Replace with generated-file notice
# ============================================================
cat > docs/api/openapi.yaml << 'EOF'
# =============================================================================
# THIS FILE IS AUTO-GENERATED — DO NOT EDIT MANUALLY
# =============================================================================
#
# Source of truth: typespec/ directory
#
# To regenerate:
#   pnpm tsp compile typespec/
#
# To validate without regenerating:
#   pnpm tsp compile typespec/ --no-emit
#
# The TypeSpec compiler writes the canonical OpenAPI 3.1 specification here.
# Any manual edits to this file will be overwritten on the next compile.
# =============================================================================
EOF

# ============================================================
# .github/workflows/typespec.yml
# ============================================================
cat > .github/workflows/typespec.yml << 'EOF'
name: TypeSpec

on:
  push:
    branches: [main]
    paths:
      - "typespec/**"
      - "tsp-config.yaml"
      - "docs/api/openapi.yaml"
  pull_request:
    branches: [main]
    paths:
      - "typespec/**"
      - "tsp-config.yaml"
      - "docs/api/openapi.yaml"

jobs:
  compile:
    name: Compile and Validate TypeSpec
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 10.6.2
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile

      - name: Compile TypeSpec
        run: pnpm tsp compile typespec/

      - name: Assert openapi.yaml was not modified uncommitted
        run: |
          if ! git diff --quiet docs/api/openapi.yaml; then
            echo ""
            echo "ERROR: docs/api/openapi.yaml is out of sync with the TypeSpec source."
            echo "Run 'pnpm tsp compile typespec/' locally and commit the result."
            echo ""
            git diff docs/api/openapi.yaml
            exit 1
          fi

      - name: Validate generated OpenAPI with Redocly
        run: npx --yes @redocly/cli lint docs/api/openapi.yaml
EOF

# =============================================================================
# 4. POLICY AS CODE — CHECKOV
# =============================================================================

# ============================================================
# .checkov.yaml
# ============================================================
cat > .checkov.yaml << 'EOF'
# Checkov policy-as-code configuration.
# https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html

# Scan these directories and files for IaC misconfigurations.
directory:
  - infra
  - .github/workflows

file:
  - docker-compose.yml

# Output
output:
  - cli
  - json

# Minimum severity level to report and fail on.
# LOW | MEDIUM | HIGH | CRITICAL
soft-fail-on:
  - LOW
  - MEDIUM

# Fail the pipeline on these severities.
# A non-zero exit code is returned if any of these are found.
hard-fail-on:
  - HIGH
  - CRITICAL

# Suppress known false-positives that are irrelevant to this project.
# Format: CHECK_ID: reason
skip-check:
  # docker-compose.yml: Local development service — no production TLS required.
  - CKV_DOCKER_2
  # docker-compose.yml: Keycloak admin password is local-dev only, not a secret.
  - CKV_SECRET_6
  # GitHub Actions: Pinning third-party actions to SHAs is preferred but not
  # enforced in this project at this time. Track via Renovate instead.
  - CKV_GH_1

# Compact output for CI readability
compact: true

# Exit code behaviour
# 0 = no failures at or above hard-fail-on threshold
# 1 = one or more failures at or above hard-fail-on threshold
EOF

# ============================================================
# .github/workflows/infra-policy.yml
# ============================================================
cat > .github/workflows/infra-policy.yml << 'EOF'
name: Infrastructure Policy

on:
  push:
    branches: [main]
    paths:
      - "infra/**"
      - "docker-compose.yml"
      - ".checkov.yaml"
      - ".github/workflows/**"
  pull_request:
    branches: [main]
    paths:
      - "infra/**"
      - "docker-compose.yml"
      - ".checkov.yaml"
      - ".github/workflows/**"
  schedule:
    # Run weekly even without changes to catch newly released checks.
    - cron: "0 7 * * 1"
  workflow_dispatch:

jobs:
  checkov:
    name: Checkov Policy Scan
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          config_file: .checkov.yaml
          output_format: cli,sarif
          output_file_path: console,checkov-results.sarif
          download_external_modules: false

      - name: Upload SARIF to GitHub Security tab
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: checkov-results.sarif
          category: checkov
EOF

# ============================================================
# infra/README.md
# ============================================================
cat > infra/README.md << 'EOF'
# Infrastructure

This directory contains all Infrastructure as Code (IaC) for the Ardtire Governance Platform.

All files in this directory are scanned by [Checkov](https://www.checkov.io/) on every CI run
and on a weekly schedule. The policy configuration is in `.checkov.yaml` at the repository root.

## Structure

```
infra/
├── terraform/        # (planned) Terraform modules for VPS provisioning
├── ansible/          # (planned) Ansible playbooks for server configuration
└── scripts/          # (planned) Operational shell scripts
```

## Policy Enforcement

Checkov scans for:
- Exposed ports and insecure security group rules
- Unencrypted storage
- Missing resource tags
- Misconfigured IAM policies
- Docker / Compose misconfigurations
- GitHub Actions workflow security issues

Any HIGH or CRITICAL severity finding fails the CI pipeline.
Suppressions must be documented in `.checkov.yaml` with a justification comment.

## Adding Infrastructure

Before adding any IaC:
1. Review the [Architectural Constraints](../docs/architecture/constraints.md).
2. Open an ADR documenting the infrastructure decision.
3. Verify that `just policy-check` passes locally before pushing.
EOF

# =============================================================================
# 5. UPDATE EXISTING FILES (full replacements)
# =============================================================================

# ============================================================
# turbo.json — adds typespec compile task
# ============================================================
cat > turbo.json << 'EOF'
{
  "$schema": "https://turbo.build/schema.json",
  "ui": "tui",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", ".env"],
      "outputs": ["dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "test": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$"],
      "outputs": ["coverage/**"],
      "cache": true
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", "tsconfig.json"],
      "cache": true
    },
    "lint": {
      "inputs": ["$TURBO_DEFAULT$", "biome.json"],
      "cache": true
    },
    "clean": {
      "cache": false
    },
    "db:generate": {
      "cache": false
    },
    "db:migrate": {
      "cache": false
    },
    "db:seed": {
      "cache": false
    },
    "typespec:compile": {
      "inputs": ["typespec/**", "tsp-config.yaml"],
      "outputs": ["docs/api/openapi.yaml"],
      "cache": true
    }
  }
}
EOF

# ============================================================
# package.json — adds TypeSpec devDeps + tsp scripts
# ============================================================
cat > package.json << 'EOF'
{
  "name": "ardtire-governance-platform",
  "version": "0.0.0",
  "private": true,
  "description": "A production-grade digital governance platform for the Ardtire Society, supporting membership governance, proposals, deliberation, voting, ratification, publication, and auditable institutional records.",
  "author": {
    "name": "Thomas J. Carter",
    "email": "thomas.carter@appliedinnovationcorp.com",
    "url": "https://www.ardtiresociety.org"
  },
  "license": "UNLICENSED",
  "homepage": "https://www.ardtiresociety.org",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/thomas-j-carter/ardtire-governance-platform.git"
  },
  "engines": {
    "node": ">=22",
    "pnpm": ">=10.6.2"
  },
  "packageManager": "pnpm@10.6.2",
  "scripts": {
    "dev": "turbo dev",
    "build": "turbo build",
    "test": "turbo test",
    "lint": "biome lint .",
    "format": "biome format --write .",
    "typecheck": "turbo typecheck",
    "check": "biome check .",
    "coverage": "vitest run --coverage",
    "clean": "turbo clean",
    "db:generate": "turbo db:generate",
    "db:migrate": "turbo db:migrate",
    "db:seed": "turbo db:seed",
    "changeset": "changeset",
    "version-packages": "changeset version",
    "deps:check": "syncpack list-mismatches",
    "deps:fix": "syncpack fix-mismatches",
    "typespec:compile": "tsp compile typespec/",
    "typespec:validate": "tsp compile typespec/ --no-emit",
    "typespec:watch": "tsp compile typespec/ --watch"
  },
  "devDependencies": {
    "@biomejs/biome": "1.9.4",
    "@changesets/cli": "2.27.12",
    "@commitlint/cli": "19.8.0",
    "@commitlint/config-conventional": "19.8.0",
    "@commitlint/types": "19.8.0",
    "@typespec/compiler": "0.63.0",
    "@typespec/http": "0.63.0",
    "@typespec/openapi3": "0.63.0",
    "@typespec/rest": "0.63.0",
    "knip": "5.50.5",
    "lefthook": "1.11.13",
    "syncpack": "13.0.0",
    "turbo": "2.5.0",
    "typescript": "5.8.3",
    "vitest": "3.1.1"
  }
}
EOF

# ============================================================
# justfile — adds typespec and policy tasks
# ============================================================
cat > justfile << 'EOF'
set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default: list all available tasks
default:
  @just --list

# ── Dependencies ──────────────────────────────────────────────────────────────

# Install all dependencies
install:
  pnpm install

# Check for dependency version mismatches across workspaces
deps-check:
  pnpm syncpack list-mismatches

# Fix dependency version mismatches across workspaces
deps-fix:
  pnpm syncpack fix-mismatches

# ── Development ───────────────────────────────────────────────────────────────

# Start all apps in development mode
dev:
  pnpm turbo dev

# ── Build ─────────────────────────────────────────────────────────────────────

# Build all packages and apps
build:
  pnpm turbo build

# ── Code Quality ──────────────────────────────────────────────────────────────

# Run Biome linter
lint:
  pnpm biome lint .

# Run Biome formatter (writes changes)
format:
  pnpm biome format --write .

# Run TypeScript type checking across all packages
typecheck:
  pnpm turbo typecheck

# Umbrella: lint + typecheck + test
check:
  just lint
  just typecheck
  just test

# ── Testing ───────────────────────────────────────────────────────────────────

# Run all tests
test:
  pnpm turbo test

# Run tests in watch mode
test-watch:
  pnpm vitest watch

# Run tests with coverage report
coverage:
  pnpm vitest run --coverage

# ── Database ──────────────────────────────────────────────────────────────────

# Start only the database service
db-up:
  docker compose up postgres -d

# Stop the database service
db-down:
  docker compose stop postgres

# Drop and recreate the dev database, then migrate
db-reset:
  docker compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS ardtire_dev;"
  docker compose exec postgres psql -U postgres -c "CREATE DATABASE ardtire_dev;"
  just db-migrate

# Generate Prisma client
db-generate:
  pnpm turbo db:generate

# Run pending migrations
db-migrate:
  pnpm turbo db:migrate

# Seed the database with development data
db-seed:
  pnpm turbo db:seed

# ── Docker Compose ────────────────────────────────────────────────────────────

# Start all local services
compose-up:
  docker compose up -d

# Stop all local services
compose-down:
  docker compose down

# Stream logs from all services
compose-logs:
  docker compose logs -f

# ── TypeSpec (Schema-Driven API) ──────────────────────────────────────────────

# Compile TypeSpec definitions → generates docs/api/openapi.yaml
typespec-compile:
  pnpm tsp compile typespec/

# Validate TypeSpec without writing output (dry run)
typespec-validate:
  pnpm tsp compile typespec/ --no-emit

# Watch TypeSpec and recompile on changes
typespec-watch:
  pnpm tsp compile typespec/ --watch

# ── Policy as Code ────────────────────────────────────────────────────────────

# Run Checkov policy scan locally (requires checkov in PATH)
policy-check:
  checkov --config-file .checkov.yaml

# ── Contracts & Generation ────────────────────────────────────────────────────

# Generate API clients and types from OpenAPI spec (after typespec-compile)
contracts-generate:
  echo "contracts-generate: not yet implemented"

# Validate OpenAPI spec with Redocly
contracts-validate:
  npx @redocly/cli lint docs/api/openapi.yaml

# ── Documentation ─────────────────────────────────────────────────────────────

# Validate documentation structure
docs-validate:
  echo "docs-validate: not yet implemented"

# ── Scaffolding ───────────────────────────────────────────────────────────────

# Run Turborepo generators to scaffold new apps or packages
scaffold:
  pnpm turbo gen

# ── Maintenance ───────────────────────────────────────────────────────────────

# Remove all build artifacts, turbo cache, and coverage
clean:
  find . -name "dist" -not -path "*/node_modules/*" -exec rm -rf {} + 2>/dev/null || true
  find . -name ".turbo" -not -path "*/node_modules/*" -exec rm -rf {} + 2>/dev/null || true
  find . -name "coverage" -not -path "*/node_modules/*" -exec rm -rf {} + 2>/dev/null || true
  find . -name "*.tsbuildinfo" -not -path "*/node_modules/*" -delete 2>/dev/null || true
  echo "Clean complete."

# Verify toolchain versions and environment prerequisites
doctor:
  @echo "=== Ardtire Governance Platform — Environment Check ==="
  @echo "Node:           $(node --version)"
  @echo "pnpm:           $(pnpm --version)"
  @echo "Docker:         $(docker --version)"
  @echo "Docker Compose: $(docker compose version)"
  @echo "mise:           $(mise --version)"
  @echo "just:           $(just --version)"
  @echo "Checkov:        $(checkov --version 2>/dev/null || echo 'not installed')"
  @echo "TypeSpec:       $(pnpm tsp --version 2>/dev/null || echo 'not installed (run pnpm install)')"
  @echo "=== All checks passed ==="

# Run the full CI pipeline locally (including typespec and policy)
ci-local:
  just install
  just typespec-validate
  just check
  just policy-check
  just build
EOF

# ============================================================
# .env.example — add OTel variables
# ============================================================
cat >> .env.example << 'EOF'

# OpenTelemetry
# Set OTEL_ENABLED=false to disable OTel instrumentation entirely (useful for bare-bones local runs)
OTEL_ENABLED=true
OTEL_SERVICE_NAME=gov-api
OTEL_SERVICE_VERSION=0.0.0
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
EOF

echo ""
echo "============================================================"
echo "  scaffold-addendum.sh complete."
echo "============================================================"
echo ""
echo "Added:"
echo "  .devcontainer/devcontainer.json"
echo "  .devcontainer/post-create.sh"
echo "  packages/observability/  (OTel SDK, tracer, metrics, logger, Hono middleware)"
echo "  typespec/  (main.tsp, common.tsp, health.tsp, members.tsp, governance.tsp)"
echo "  tsp-config.yaml"
echo "  .github/workflows/typespec.yml"
echo "  .github/workflows/infra-policy.yml"
echo "  .checkov.yaml"
echo "  infra/  (README.md, .gitkeep)"
echo ""
echo "Updated (full replacement):"
echo "  package.json  — TypeSpec devDeps, tsp:compile/validate/watch scripts"
echo "  turbo.json    — typespec:compile task"
echo "  justfile      — typespec-* and policy-check tasks"
echo "  docs/api/openapi.yaml  — replaced with generated-file notice"
echo "  .env.example  — OTel environment variables appended"
echo ""
echo "Next steps:"
echo "  pnpm install              # pull new TypeSpec + OTel devDeps"
echo "  pnpm typespec:compile     # generate docs/api/openapi.yaml from TypeSpec"
echo "  just doctor               # verify toolchain"
echo ""
echo "App entry points: import '@ardtire/observability/sdk' as the FIRST line."
EOF

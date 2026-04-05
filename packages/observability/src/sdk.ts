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

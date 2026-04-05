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
   * Public endpoint — no authentication required.
   */
  @get
  @summary("Liveness check")
  @useAuth([])
  liveness(): {
    @statusCode statusCode: 200;
    @body body: HealthResponse;
  };

  /**
   * Readiness check. Returns 200 only when all dependencies are healthy.
   * Used by load balancers and orchestrators to gate traffic.
   * Public endpoint — no authentication required.
   */
  @get
  @route("ready")
  @summary("Readiness check")
  @useAuth([])
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

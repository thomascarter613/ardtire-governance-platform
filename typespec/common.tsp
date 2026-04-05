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

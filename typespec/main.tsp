/**
 * Ardtire Governance API — TypeSpec root.
 *
 * This file is the TypeSpec compiler entry point.
 * Running `tsp compile typespec/` regenerates docs/api/openapi.yaml.
 *
 * DO NOT manually edit docs/api/openapi.yaml — it is a generated artifact.
 * All API changes must originate here as TypeSpec definitions.
 *
 * Compile:  pnpm typespec:compile
 * Watch:    pnpm typespec:watch
 * Validate: pnpm typespec:validate
 */
import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi";    // Required: provides @info decorator
import "@typespec/openapi3";   // Required: provides the OpenAPI 3.x emitter

import "./common.tsp";
import "./health.tsp";
import "./members.tsp";
import "./governance.tsp";

using TypeSpec.Http;
using TypeSpec.Rest;
using TypeSpec.OpenAPI;       // Brings @info into scope

/**
 * The Ardtire Governance API.
 *
 * The canonical governance API for the Ardtire Society. This API is the single
 * authoritative source of truth for all governance state. All governance outcomes,
 * membership records, and audit events originate here.
 *
 * When this API and any other system disagree on governance state, this API is correct.
 */
@service({ title: "Ardtire Governance API" })
@info({
  version: "0.1.0",
  contact: {
    name: "Thomas J. Carter",
    email: "thomas.carter@appliedinnovationcorp.com",
    url: "https://www.ardtiresociety.org",
  },
  license: {
    name: "Proprietary",
  },
})
@server("https://api.ardtiresociety.org", "Production")
@server("https://staging-api.ardtiresociety.org", "Staging")
@server("http://localhost:3001", "Local development")
@useAuth(BearerAuth)
namespace ArdtireGovernanceApi;

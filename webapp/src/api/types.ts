/*
 * Re-export the generated OpenAPI contract types (ADR-0017). These are
 * generated from docs/api/openapi.yaml by openapi-typescript and are the single
 * source of truth for request/response shapes. The web client never hand-writes
 * API types; a contract change surfaces here as a compile error.
 *
 * The web CI lane runs on docs/api/** too, so regenerating the contract retypes
 * the whole client.
 */
export type {
  paths,
  components,
  operations,
} from "../../../docs/api/generated/types";

import type { components } from "../../../docs/api/generated/types";

export type MoneyMinorUnits = components["schemas"]["MoneyMinorUnits"];
export type HealthStatus = components["schemas"]["HealthStatus"];
export type Source = components["schemas"]["Source"];
export type SourceList = components["schemas"]["SourceList"];
export type SourceKind = Source["kind"];

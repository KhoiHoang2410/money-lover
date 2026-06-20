import createClient, { type Client } from "openapi-fetch";
import type { paths } from "@/api/types";

/*
 * The ONE place HTTP happens (ADR-0018). Every request goes through this typed
 * `openapi-fetch` client, generated from the OpenAPI contract types — so a
 * request path, param, or response shape that drifts from the contract is a
 * TypeScript compile error, not a runtime surprise.
 *
 * The API base URL is configurable per environment via VITE_API_BASE_URL.
 */

export const API_BASE_URL: string =
  import.meta.env.VITE_API_BASE_URL ?? "http://localhost:3000";

let accessToken: string | undefined;

/** Set/clear the bearer token used on authenticated requests. */
export function setAccessToken(token: string | undefined): void {
  accessToken = token;
}

export function createApiClient(baseUrl: string = API_BASE_URL): Client<paths> {
  const client = createClient<paths>({
    baseUrl,
    headers: { Accept: "application/json" },
  });

  // Attach the bearer token (when present) to every request.
  client.use({
    onRequest({ request }) {
      if (accessToken) {
        request.headers.set("Authorization", `Bearer ${accessToken}`);
      }
      return request;
    },
  });

  return client;
}

export const apiClient: Client<paths> = createApiClient();

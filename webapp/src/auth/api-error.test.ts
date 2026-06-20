import { describe, it, expect } from "vitest";
import { ApiError, toApiError } from "./api-error";

/*
 * The API speaks one error envelope (ADR-0018): { error: { code, message,
 * details? } }. toApiError normalises an openapi-fetch error body so the auth
 * forms can render a top-level message and per-field 422 errors inline.
 */
describe("toApiError", () => {
  it("maps the envelope's code + message", () => {
    const err = toApiError({
      error: { code: "invalid_credentials", message: "Wrong password" },
    });
    expect(err).toBeInstanceOf(ApiError);
    expect(err.code).toBe("invalid_credentials");
    expect(err.message).toBe("Wrong password");
    expect(err.fieldErrors).toEqual({});
  });

  it("exposes per-field 422 details via fieldError()", () => {
    const err = toApiError({
      error: {
        code: "validation_failed",
        message: "Validation failed",
        details: { username: ["has already been taken"] },
      },
    });
    expect(err.fieldError("username")).toBe("has already been taken");
    expect(err.fieldError("password")).toBeUndefined();
  });

  it("falls back to a generic ApiError for an unknown body shape", () => {
    const err = toApiError({ something: "else" });
    expect(err).toBeInstanceOf(ApiError);
    expect(err.code).toBe("unknown_error");
    expect(err.message.length).toBeGreaterThan(0);
  });
});

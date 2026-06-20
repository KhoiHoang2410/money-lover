/*
 * The API speaks one error envelope (ADR-0018): { error: { code, message,
 * details? } }. `details` is an optional per-field map for 422 validation
 * failures (e.g. { username: ["has already been taken"] }). This normalises an
 * openapi-fetch error body into a typed shape the auth forms can render inline.
 */
export interface ApiErrorShape {
  code: string;
  message: string;
  details?: Record<string, string[]>;
}

export class ApiError extends Error {
  readonly code: string;
  readonly fieldErrors: Record<string, string[]>;

  constructor(shape: ApiErrorShape) {
    super(shape.message);
    this.name = "ApiError";
    this.code = shape.code;
    this.fieldErrors = shape.details ?? {};
  }

  /** First message for a field, if the API attached one. */
  fieldError(field: string): string | undefined {
    return this.fieldErrors[field]?.[0];
  }
}

const FALLBACK: ApiErrorShape = {
  code: "unknown_error",
  message: "Something went wrong. Please try again.",
};

/** Coerce an unknown openapi-fetch error body into an ApiError. */
export function toApiError(error: unknown): ApiError {
  if (error && typeof error === "object" && "error" in error) {
    const envelope = (error as { error: unknown }).error;
    if (envelope && typeof envelope === "object" && "message" in envelope) {
      const e = envelope as Partial<ApiErrorShape>;
      return new ApiError({
        code: e.code ?? FALLBACK.code,
        message: e.message ?? FALLBACK.message,
        details: e.details,
      });
    }
  }
  return new ApiError(FALLBACK);
}

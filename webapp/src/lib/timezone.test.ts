import { describe, it, expect, afterEach, vi } from "vitest";
import { detectTimezone, DEFAULT_TIMEZONE } from "./timezone";

/*
 * Timezone detection (PRD Identity & access). The browser's IANA zone is sent on
 * register; when the environment can't report a usable zone we fall back to the
 * product's home market, Asia/Ho_Chi_Minh.
 */
function mockResolvedTimeZone(timeZone: unknown): void {
  vi.spyOn(Intl, "DateTimeFormat").mockReturnValue({
    resolvedOptions: () => ({ timeZone }),
  } as unknown as Intl.DateTimeFormat);
}

describe("detectTimezone", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("returns the browser's resolved IANA zone when present", () => {
    mockResolvedTimeZone("Europe/Paris");
    expect(detectTimezone()).toBe("Europe/Paris");
  });

  it("falls back to Asia/Ho_Chi_Minh when the zone is empty", () => {
    mockResolvedTimeZone("");
    expect(detectTimezone()).toBe(DEFAULT_TIMEZONE);
    expect(DEFAULT_TIMEZONE).toBe("Asia/Ho_Chi_Minh");
  });

  it("falls back to Asia/Ho_Chi_Minh when the zone is undefined", () => {
    mockResolvedTimeZone(undefined);
    expect(detectTimezone()).toBe(DEFAULT_TIMEZONE);
  });

  it("falls back to Asia/Ho_Chi_Minh when Intl throws", () => {
    vi.spyOn(Intl, "DateTimeFormat").mockImplementation(() => {
      throw new Error("no Intl");
    });
    expect(detectTimezone()).toBe(DEFAULT_TIMEZONE);
  });
});

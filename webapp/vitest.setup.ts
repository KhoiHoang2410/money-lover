import "@testing-library/jest-dom/vitest";
import { vi } from "vitest";

/*
 * jsdom ships no matchMedia, which the app shell's responsive hook depends on.
 * Provide a minimal, overridable stub: defaults to "no match" (mobile-first /
 * drawer mode). Tests that exercise sidebar/rail/drawer override window.matchMedia
 * per-case (see AppShell tests).
 */
if (typeof window !== "undefined" && !window.matchMedia) {
  window.matchMedia = (query: string): MediaQueryList =>
    ({
      matches: false,
      media: query,
      onchange: null,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }) as unknown as MediaQueryList;
}

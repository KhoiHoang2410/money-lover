import { useMediaQuery } from "@/lib/use-media-query";

export type ShellMode = "sidebar" | "rail" | "drawer";

/*
 * The app shell's responsive mode (PRD IA): full sidebar (≥1024px) → icon-rail
 * (≥768px) → hamburger drawer (<768px). Driven by matchMedia so exactly one nav
 * lives in the DOM per breakpoint — keeping focus order clean and the behavior
 * unit-testable by mocking matchMedia.
 */
export function useShellMode(): ShellMode {
  const isDesktop = useMediaQuery("(min-width: 1024px)");
  const isTablet = useMediaQuery("(min-width: 768px)");
  if (isDesktop) return "sidebar";
  if (isTablet) return "rail";
  return "drawer";
}

import { useEffect, useState } from "react";

/*
 * Subscribe to a CSS media query. Drives the app shell's sidebar ↔ icon-rail ↔
 * drawer switch off real breakpoints (rather than CSS-only visibility) so the
 * correct nav is the only one in the DOM — keeping focus order and the mobile
 * drawer's a11y semantics clean, and the behavior unit-testable via matchMedia.
 */
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState<boolean>(() =>
    typeof window !== "undefined" && typeof window.matchMedia === "function"
      ? window.matchMedia(query).matches
      : false,
  );

  useEffect(() => {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
      return;
    }
    const list = window.matchMedia(query);
    const onChange = () => setMatches(list.matches);
    onChange();
    list.addEventListener("change", onChange);
    return () => list.removeEventListener("change", onChange);
  }, [query]);

  return matches;
}

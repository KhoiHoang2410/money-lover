/*
 * The hard-coded suggested set (CONTEXT.md "Starter envelopes"). The actual seed
 * is server-side and idempotent on names (POST /api/starter_envelopes); this
 * list only drives the picker's preview — which members already exist (shown
 * disabled) and which one becomes the Reserve when none exists yet. Names mirror
 * the backend's canonical set so the case-insensitive, trimmed match lines up.
 */
export interface StarterEnvelope {
  name: string;
  icon: string;
  /** The designated Reserve — only becomes the Reserve if the user has none. */
  isReserve?: boolean;
}

export const STARTER_ENVELOPES: readonly StarterEnvelope[] = [
  { name: "Food", icon: "🍜" },
  { name: "Transport", icon: "🛵" },
  { name: "Rent", icon: "🏠" },
  { name: "Utilities", icon: "💡" },
  { name: "Entertainment", icon: "🎬" },
  { name: "Health", icon: "💊" },
  { name: "Savings", icon: "🐷", isReserve: true },
];

/** Normalise a name for the case-insensitive, trimmed existence check. */
export function normalizeName(name: string): string {
  return name.trim().toLocaleLowerCase();
}

/*
 * Timezone detection for registration (PRD Identity & access). The User's
 * timezone drives month boundaries, "today", and resets, so we capture the
 * browser's IANA zone at sign-up. Falls back to Asia/Ho_Chi_Minh — the product's
 * home market — when the environment can't report a usable zone.
 */
export const DEFAULT_TIMEZONE = "Asia/Ho_Chi_Minh";

export function detectTimezone(): string {
  try {
    const zone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    return zone && zone.length > 0 ? zone : DEFAULT_TIMEZONE;
  } catch {
    return DEFAULT_TIMEZONE;
  }
}

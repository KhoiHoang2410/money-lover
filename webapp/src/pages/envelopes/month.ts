/*
 * The current month as `YYYY-MM` for the allocation-template default. The API
 * resolves month boundaries in the caller's timezone; this only seeds the
 * <input type="month"> default, so the browser-local month is sufficient.
 */
export function currentMonth(now: Date = new Date()): string {
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

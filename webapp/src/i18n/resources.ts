/*
 * Locale resources (PRD i18n). Authored as YAML, one file per page, namespaced
 * by page (the file's top-level key). All pages merge into a single i18next
 * namespace so every string is reached as `t("<page>.<textName>")` —
 * e.g. t("common.appName"), t("health.title").
 *
 * New page → drop a `<page>.yaml` under each locale; the glob picks it up.
 */

export const SUPPORTED_LOCALES = ["en-US", "vi-VN"] as const;
export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number];

export const FALLBACK_LOCALE: SupportedLocale = "en-US";

export type PageResources = Record<string, unknown>;
export type LocaleResources = Record<string, PageResources>;

const modules = import.meta.glob<{ default: PageResources }>(
  "./locales/*/*.yaml",
  { eager: true },
);

function buildResources(): Record<string, LocaleResources> {
  const out: Record<string, LocaleResources> = {};
  for (const [path, mod] of Object.entries(modules)) {
    // "./locales/en-US/health.yaml" → locale segment "en-US"
    const locale = path.split("/")[2];
    out[locale] ??= {};
    Object.assign(out[locale], mod.default);
  }
  return out;
}

export const resources = buildResources();

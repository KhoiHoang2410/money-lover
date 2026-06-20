import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import {
  resources,
  SUPPORTED_LOCALES,
  FALLBACK_LOCALE,
  type SupportedLocale,
} from "./resources";

/*
 * i18next harness. Default locale comes from the browser, persisted to
 * localStorage (PRD i18n). The single "translation" namespace holds every page
 * (keys are `<page>.<textName>`). Money/number/date formatting is NOT done here
 * — it uses Intl directly (see lib/money.ts), independent of the UI-copy locale.
 */

const i18nResources = Object.fromEntries(
  Object.entries(resources).map(([locale, pages]) => [
    locale,
    { translation: pages },
  ]),
);

void i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: i18nResources,
    supportedLngs: [...SUPPORTED_LOCALES, "en", "vi"],
    fallbackLng: FALLBACK_LOCALE,
    interpolation: { escapeValue: false },
    detection: {
      order: ["localStorage", "navigator"],
      lookupLocalStorage: "money-lover.locale",
      caches: ["localStorage"],
    },
  });

export function changeLocale(locale: SupportedLocale): Promise<unknown> {
  return i18n.changeLanguage(locale) as Promise<unknown>;
}

export { SUPPORTED_LOCALES, type SupportedLocale };
export default i18n;

import { useTranslation } from "react-i18next";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { SUPPORTED_LOCALES, type SupportedLocale } from "@/i18n";

// Language switcher (PRD i18n). Swaps every visible string; persisted via the
// i18next localStorage detector.
export function LanguageSwitcher() {
  const { t, i18n } = useTranslation();
  const current = (
    SUPPORTED_LOCALES as readonly string[]
  ).includes(i18n.language)
    ? (i18n.language as SupportedLocale)
    : SUPPORTED_LOCALES[0];

  return (
    <Select
      value={current}
      onValueChange={(value) => void i18n.changeLanguage(value)}
    >
      <SelectTrigger className="w-44" aria-label={t("common.language")}>
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="en-US">{t("common.english")}</SelectItem>
        <SelectItem value="vi-VN">{t("common.vietnamese")}</SelectItem>
      </SelectContent>
    </Select>
  );
}

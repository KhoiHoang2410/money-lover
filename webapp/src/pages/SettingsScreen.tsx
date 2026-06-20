import { useState } from "react";
import { useTranslation } from "react-i18next";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";
import { useAuth } from "@/auth/context";
import { detectTimezone } from "@/lib/timezone";

// A small, curated set of IANA zones for the stub control. Full timezone
// management (and persistence to the User via the API) grows in a later wave.
const TIMEZONE_OPTIONS = [
  "Asia/Ho_Chi_Minh",
  "Asia/Bangkok",
  "Asia/Singapore",
  "Asia/Tokyo",
  "Europe/London",
  "America/New_York",
  "America/Los_Angeles",
] as const;

const TIMEZONE_KEY = "money-lover.timezone";

function readStoredTimezone(): string {
  try {
    return localStorage.getItem(TIMEZONE_KEY) ?? detectTimezone();
  } catch {
    return detectTimezone();
  }
}

export function SettingsScreen() {
  const { t } = useTranslation();
  const { logout } = useAuth();
  const [timezone, setTimezone] = useState(() => readStoredTimezone());

  // Ensure the detected/stored zone is selectable even if not in the curated set.
  const options = TIMEZONE_OPTIONS.includes(
    timezone as (typeof TIMEZONE_OPTIONS)[number],
  )
    ? TIMEZONE_OPTIONS
    : [timezone, ...TIMEZONE_OPTIONS];

  function onTimezoneChange(value: string) {
    setTimezone(value);
    try {
      localStorage.setItem(TIMEZONE_KEY, value);
    } catch {
      /* ignore disabled storage */
    }
  }

  return (
    <div className="flex max-w-xl flex-col gap-6">
      <section className="rounded-lg bg-card p-7">
        <h2 className="text-lg font-bold">{t("settings.preferencesTitle")}</h2>

        <div className="mt-5 flex flex-col gap-2">
          <span className="text-sm font-medium text-foreground">
            {t("settings.timezoneLabel")}
          </span>
          <Select value={timezone} onValueChange={onTimezoneChange}>
            <SelectTrigger
              className="w-full"
              aria-label={t("settings.timezoneLabel")}
            >
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {options.map((zone) => (
                <SelectItem key={zone} value={zone}>
                  {zone}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <p className="text-xs text-muted-foreground">
            {t("settings.timezoneHint")}
          </p>
        </div>

        <div className="mt-6 flex flex-col gap-2">
          <span className="text-sm font-medium text-foreground">
            {t("settings.languageLabel")}
          </span>
          <LanguageSwitcher />
        </div>
      </section>

      <section className="rounded-lg bg-card p-7">
        <h2 className="text-lg font-bold">{t("settings.accountTitle")}</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          {t("settings.logoutHint")}
        </p>
        <Button
          variant="destructive"
          className="mt-4"
          onClick={() => void logout()}
        >
          {t("settings.logoutButton")}
        </Button>
      </section>
    </div>
  );
}

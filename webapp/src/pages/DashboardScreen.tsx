import { useTranslation } from "react-i18next";
import { useAuth } from "@/auth/context";

// Dashboard placeholder for this slice — the auth + shell gate. The net-worth /
// signals / key cards land in a later wave (PRD roadmap step 2).
export function DashboardScreen() {
  const { t } = useTranslation();
  const { user } = useAuth();

  return (
    <div className="flex flex-col gap-6">
      <section className="rounded-lg bg-hero p-7 text-hero-foreground">
        <span className="text-sm font-medium opacity-70">
          {t("dashboard.welcome")}
        </span>
        <p className="mt-1 text-3xl font-bold">{user?.username}</p>
        <p className="mt-2 text-sm opacity-70">{t("dashboard.subtitle")}</p>
      </section>

      <section className="rounded-lg bg-card p-7">
        <h2 className="text-lg font-bold">{t("dashboard.comingSoonTitle")}</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          {t("dashboard.comingSoonBody")}
        </p>
      </section>
    </div>
  );
}

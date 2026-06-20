import { useNavigate } from "react-router";
import { useTranslation } from "react-i18next";
import { useAuth } from "@/auth/context";

function initialsOf(username: string): string {
  return username.trim().slice(0, 2).toUpperCase() || "?";
}

// Profile chip in the top bar: avatar + handle. Opens Settings (which holds the
// logout action and the timezone/language stubs for this slice).
export function ProfileChip() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { user } = useAuth();
  const username = user?.username ?? "";

  return (
    <button
      type="button"
      onClick={() => void navigate("/settings")}
      aria-label={t("shell.openSettings")}
      className="flex items-center gap-2 rounded-full border border-border bg-card py-1 pl-1 pr-3 text-sm font-medium text-foreground transition-colors hover:bg-accent"
    >
      <span className="grid h-7 w-7 place-items-center rounded-full bg-primary text-xs font-bold text-primary-foreground">
        {initialsOf(username)}
      </span>
      <span className="max-w-32 truncate">{username}</span>
    </button>
  );
}

import { useTranslation } from "react-i18next";
import { cn } from "@/lib/utils";
import { NavList } from "./NavList";

interface SidebarProps {
  /** Icon-rail mode (tablet): narrow column, icons only. */
  collapsed?: boolean;
}

// Persistent left column for tablet+ (desktop sidebar / tablet icon-rail). The
// mobile drawer reuses NavList directly inside a sheet instead of this column.
export function Sidebar({ collapsed = false }: SidebarProps) {
  const { t } = useTranslation();

  return (
    <aside
      data-testid="app-sidebar"
      data-mode={collapsed ? "rail" : "sidebar"}
      className={cn(
        "sticky top-0 flex h-dvh shrink-0 flex-col gap-6 border-r border-border bg-card px-3 py-5",
        collapsed ? "w-16 items-center" : "w-60",
      )}
    >
      <div className={cn("px-2", collapsed && "px-0")}>
        {collapsed ? (
          <span
            className="grid h-9 w-9 place-items-center rounded-full bg-primary text-base font-bold text-primary-foreground"
            aria-label={t("common.appName")}
          >
            M
          </span>
        ) : (
          <span className="text-lg font-bold tracking-tight text-foreground">
            {t("common.appName")}
          </span>
        )}
      </div>
      <NavList collapsed={collapsed} />
    </aside>
  );
}

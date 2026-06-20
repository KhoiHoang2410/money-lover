import { NavLink } from "react-router";
import { useTranslation } from "react-i18next";
import { cn } from "@/lib/utils";
import { NAV_ITEMS } from "./nav-items";

interface NavListProps {
  /** Icon-only rail (tablet). Labels collapse to accessible tooltips/titles. */
  collapsed?: boolean;
  /** Fired after navigating — lets the mobile drawer close itself. */
  onNavigate?: () => void;
}

// The single nav renderer shared by the sidebar, the icon-rail, and the mobile
// drawer. Active styling is the lime pill; the rest are muted ghost rows.
export function NavList({ collapsed = false, onNavigate }: NavListProps) {
  const { t } = useTranslation();

  return (
    <nav aria-label={t("nav.label")} className="flex flex-col gap-1">
      {NAV_ITEMS.map(({ key, to, icon: Icon, end }) => {
        const label = t(`nav.${key}`);
        return (
          <NavLink
            key={key}
            to={to}
            end={end}
            onClick={onNavigate}
            title={collapsed ? label : undefined}
            className={({ isActive }) =>
              cn(
                "flex items-center gap-3 rounded-full px-3 py-2.5 text-sm font-medium transition-colors",
                collapsed && "justify-center px-0",
                isActive
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-accent hover:text-foreground",
              )
            }
          >
            <Icon className="h-5 w-5 shrink-0" aria-hidden="true" />
            <span className={cn(collapsed ? "sr-only" : "truncate")}>
              {label}
            </span>
          </NavLink>
        );
      })}
    </nav>
  );
}

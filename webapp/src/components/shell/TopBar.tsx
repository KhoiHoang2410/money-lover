import { useLocation } from "react-router";
import { useTranslation } from "react-i18next";
import { Menu } from "lucide-react";
import { Button } from "@/components/ui/button";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";
import { NAV_ITEMS } from "./nav-items";
import { ProfileChip } from "./ProfileChip";

interface TopBarProps {
  /** Show the hamburger (mobile drawer mode only). */
  showMenuButton?: boolean;
  onOpenMenu?: () => void;
}

// Resolve the current page's title from the IA, longest matching path wins so
// "/" only matches the Dashboard exactly.
function usePageTitleKey(): string {
  const { pathname } = useLocation();
  const match = [...NAV_ITEMS]
    .sort((a, b) => b.to.length - a.to.length)
    .find((item) =>
      item.to === "/" ? pathname === "/" : pathname.startsWith(item.to),
    );
  return match?.key ?? "dashboard";
}

export function TopBar({ showMenuButton = false, onOpenMenu }: TopBarProps) {
  const { t } = useTranslation();
  const titleKey = usePageTitleKey();

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-border bg-background/80 px-4 backdrop-blur-md lg:px-6">
      {showMenuButton && (
        <Button
          variant="ghost"
          size="icon"
          onClick={onOpenMenu}
          aria-label={t("shell.openMenu")}
        >
          <Menu className="h-5 w-5" />
        </Button>
      )}
      <h1 className="min-w-0 flex-1 truncate text-lg font-bold tracking-tight">
        {t(`nav.${titleKey}`)}
      </h1>
      <div className="flex items-center gap-2">
        <LanguageSwitcher />
        <ProfileChip />
      </div>
    </header>
  );
}

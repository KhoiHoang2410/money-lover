import { useEffect, useState } from "react";
import { Outlet, useLocation } from "react-router";
import { useTranslation } from "react-i18next";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { NavList } from "./NavList";
import { Sidebar } from "./Sidebar";
import { TopBar } from "./TopBar";
import { useShellMode } from "./use-shell-mode";

// The authenticated chrome (PRD IA): persistent sidebar/rail at tablet+, a
// hamburger-triggered drawer on mobile-web, and a thin top bar. Feature screens
// render through <Outlet/>.
export function AppShell() {
  const { t } = useTranslation();
  const mode = useShellMode();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const { pathname } = useLocation();

  // Close the drawer on navigation and whenever we leave drawer mode.
  useEffect(() => setDrawerOpen(false), [pathname]);
  useEffect(() => {
    if (mode !== "drawer") setDrawerOpen(false);
  }, [mode]);

  return (
    <div className="flex min-h-dvh bg-background">
      {mode !== "drawer" && <Sidebar collapsed={mode === "rail"} />}

      <div className="flex min-w-0 flex-1 flex-col">
        <TopBar
          showMenuButton={mode === "drawer"}
          onOpenMenu={() => setDrawerOpen(true)}
        />
        <main className="flex-1 px-4 py-6 lg:px-8 lg:py-8">
          <Outlet />
        </main>
      </div>

      {mode === "drawer" && (
        <Dialog open={drawerOpen} onOpenChange={setDrawerOpen}>
          <DialogContent
            data-testid="app-drawer"
            className="fixed left-0 top-0 h-dvh w-72 max-w-[80vw] translate-x-0 translate-y-0 rounded-none rounded-r-lg border-r p-4"
          >
            <DialogHeader>
              <DialogTitle>{t("common.appName")}</DialogTitle>
            </DialogHeader>
            <NavList onNavigate={() => setDrawerOpen(false)} />
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
}

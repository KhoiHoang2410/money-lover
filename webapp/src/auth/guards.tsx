import { Navigate, Outlet } from "react-router";
import { useTranslation } from "react-i18next";
import { useAuth } from "./context";

// Shown while the app bootstraps a refresh on load — before we know whether the
// cookie yields a session. Avoids a flash of /login on every reload.
function SessionLoading() {
  const { t } = useTranslation();
  return (
    <div className="flex min-h-dvh items-center justify-center bg-background">
      <span className="text-sm text-muted-foreground">{t("common.loading")}</span>
    </div>
  );
}

/** Gate for app routes: unauthenticated visitors are sent to /login. */
export function RequireAuth() {
  const { status } = useAuth();
  if (status === "loading") {
    return <SessionLoading />;
  }
  if (status === "unauthed") {
    return <Navigate to="/login" replace />;
  }
  return <Outlet />;
}

/** Gate for /login + /register: authenticated users are sent to the Dashboard. */
export function RedirectIfAuthed() {
  const { status } = useAuth();
  if (status === "loading") {
    return <SessionLoading />;
  }
  if (status === "authed") {
    return <Navigate to="/" replace />;
  }
  return <Outlet />;
}

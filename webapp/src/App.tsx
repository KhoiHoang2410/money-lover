import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router";
import { AuthProvider } from "@/auth/AuthProvider";
import { RequireAuth, RedirectIfAuthed } from "@/auth/guards";
import { AppShell } from "@/components/shell/AppShell";
import { LoginScreen } from "@/pages/LoginScreen";
import { RegisterScreen } from "@/pages/RegisterScreen";
import { DashboardScreen } from "@/pages/DashboardScreen";
import { SettingsScreen } from "@/pages/SettingsScreen";
import { PlaceholderScreen } from "@/pages/PlaceholderScreen";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, refetchOnWindowFocus: true },
  },
});

/*
 * App shell (ADR-0018): TanStack Query owns server state; react-router owns
 * routing; AuthProvider owns the session. Public auth routes redirect to the
 * Dashboard once signed in; the protected route group renders inside the chrome
 * (AppShell) and bounces unauthenticated visitors to /login.
 */
export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route element={<RedirectIfAuthed />}>
              <Route path="/login" element={<LoginScreen />} />
              <Route path="/register" element={<RegisterScreen />} />
            </Route>

            <Route element={<RequireAuth />}>
              <Route element={<AppShell />}>
                <Route path="/" element={<DashboardScreen />} />
                <Route
                  path="/sources"
                  element={<PlaceholderScreen sectionKey="sources" />}
                />
                <Route
                  path="/transactions"
                  element={<PlaceholderScreen sectionKey="transactions" />}
                />
                <Route
                  path="/envelopes"
                  element={<PlaceholderScreen sectionKey="envelopes" />}
                />
                <Route
                  path="/goals"
                  element={<PlaceholderScreen sectionKey="goals" />}
                />
                <Route
                  path="/reports"
                  element={<PlaceholderScreen sectionKey="reports" />}
                />
                <Route
                  path="/reconcile"
                  element={<PlaceholderScreen sectionKey="reconcile" />}
                />
                <Route path="/settings" element={<SettingsScreen />} />
              </Route>
            </Route>

            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

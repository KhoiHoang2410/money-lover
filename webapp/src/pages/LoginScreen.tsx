import { useState, type FormEvent } from "react";
import { Link } from "react-router";
import { useTranslation } from "react-i18next";
import { Button } from "@/components/ui/button";
import { AuthLayout } from "@/components/auth/AuthLayout";
import { FormField } from "@/components/auth/FormField";
import { useAuth } from "@/auth/context";
import { ApiError } from "@/auth/api-error";

// Generic-free typed initial (keeps the i18n .tsx copy scanner unconfused).
const NO_ERROR: ApiError | null = null;

export function LoginScreen() {
  const { t } = useTranslation();
  const { login } = useAuth();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(NO_ERROR);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login({ username, password });
    } catch (err) {
      setError(err instanceof ApiError ? err : new ApiError({
        code: "unknown_error",
        message: t("auth.genericError"),
      }));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthLayout
      title={t("auth.loginTitle")}
      subtitle={t("auth.loginSubtitle")}
      footer={
        <>
          {t("auth.noAccount")}{" "}
          <Link to="/register" className="font-semibold text-primary">
            {t("auth.registerLink")}
          </Link>
        </>
      }
    >
      <form onSubmit={onSubmit} className="flex flex-col gap-4" noValidate>
        {error && error.fieldErrors && Object.keys(error.fieldErrors).length === 0 && (
          <p role="alert" className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">
            {error.message}
          </p>
        )}

        <FormField
          label={t("auth.usernameLabel")}
          name="username"
          autoComplete="username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          error={error?.fieldError("username")}
          required
        />
        <FormField
          label={t("auth.passwordLabel")}
          name="password"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={error?.fieldError("password")}
          required
        />

        <Button type="submit" size="lg" className="mt-2 w-full" disabled={submitting}>
          {submitting ? t("auth.signingIn") : t("auth.loginButton")}
        </Button>
      </form>
    </AuthLayout>
  );
}

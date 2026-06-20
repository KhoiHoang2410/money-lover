import { useMemo, useState, type FormEvent } from "react";
import { Link } from "react-router";
import { useTranslation } from "react-i18next";
import { Button } from "@/components/ui/button";
import { AuthLayout } from "@/components/auth/AuthLayout";
import { FormField } from "@/components/auth/FormField";
import { useAuth } from "@/auth/context";
import { ApiError } from "@/auth/api-error";
import { detectTimezone } from "@/lib/timezone";

// Generic-free typed initials (keeps the i18n .tsx copy scanner unconfused).
const NO_ERROR: ApiError | null = null;
const NO_FIELD_ERROR: string | null = null;

export function RegisterScreen() {
  const { t } = useTranslation();
  const { register } = useAuth();

  // Detected once on mount and sent on submit (PRD Identity & access).
  const timezone = useMemo(() => detectTimezone(), []);

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [confirmError, setConfirmError] = useState(NO_FIELD_ERROR);
  const [error, setError] = useState(NO_ERROR);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setConfirmError(null);

    if (password !== confirm) {
      setConfirmError(t("auth.passwordMismatch"));
      return;
    }

    setSubmitting(true);
    try {
      await register({ username, password, timezone });
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
      title={t("auth.registerTitle")}
      subtitle={t("auth.registerSubtitle")}
      footer={
        <>
          {t("auth.haveAccount")}{" "}
          <Link to="/login" className="font-semibold text-primary">
            {t("auth.loginLink")}
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
          autoComplete="new-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={error?.fieldError("password")}
          required
        />
        <FormField
          label={t("auth.confirmPasswordLabel")}
          name="confirmPassword"
          type="password"
          autoComplete="new-password"
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          error={confirmError ?? undefined}
          required
        />

        <p className="text-xs text-muted-foreground">
          {t("auth.timezoneNote", { timezone })}
        </p>

        <Button type="submit" size="lg" className="mt-2 w-full" disabled={submitting}>
          {submitting ? t("auth.creatingAccount") : t("auth.registerButton")}
        </Button>
      </form>
    </AuthLayout>
  );
}

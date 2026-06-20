import { useState, type FormEvent, type ReactNode } from "react";
import { useTranslation } from "react-i18next";
import type { Client } from "openapi-fetch";
import type {
  paths,
  Envelope,
  EnvelopeCreateRequest,
  EnvelopeUpdateRequest,
} from "@/api/types";
import { parseMoney } from "@/lib/money";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { ApiError } from "@/auth/api-error";
import {
  useCreateEnvelope,
  useUpdateEnvelope,
} from "./useEnvelopes";

const CURRENCY = "VND";

// Typed nulls keep the i18n copy-scanner off TS generics in .tsx (see LoginScreen).
const NO_ERROR: string | null = null;

interface EnvelopeFormDialogProps {
  client: Client<paths>;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Present → edit mode; absent → create mode. */
  envelope?: Envelope;
}

function Field({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <label className="flex flex-col gap-1.5 text-sm font-medium text-foreground">
      <span>{label}</span>
      {children}
    </label>
  );
}

/** Money input → minor units; blank counts as 0. Throws on non-numeric input. */
function toMinor(value: string): number {
  const trimmed = value.trim();
  if (trimmed === "") return 0;
  return parseMoney(trimmed, CURRENCY);
}

function optionalMinor(value: string): number | undefined {
  const trimmed = value.trim();
  if (trimmed === "") return undefined;
  return parseMoney(trimmed, CURRENCY);
}

export function EnvelopeFormDialog({
  open,
  onOpenChange,
  client,
  envelope,
}: EnvelopeFormDialogProps) {
  const { t } = useTranslation();
  const isEdit = envelope !== undefined;

  const [name, setName] = useState(envelope?.name ?? "");
  const [icon, setIcon] = useState(envelope?.icon ?? "");
  const [allocation, setAllocation] = useState(
    envelope ? String(envelope.allocation.amount_minor) : "",
  );
  const [weeklyCap, setWeeklyCap] = useState(
    envelope?.weekly_cap ? String(envelope.weekly_cap.amount_minor) : "",
  );
  const [monthlyCap, setMonthlyCap] = useState(
    envelope?.monthly_cap ? String(envelope.monthly_cap.amount_minor) : "",
  );
  const [isReserve, setIsReserve] = useState(envelope?.is_reserve ?? false);
  const [formError, setFormError] = useState(NO_ERROR);

  const createEnvelope = useCreateEnvelope(client);
  const updateEnvelope = useUpdateEnvelope(client);
  const submitting = createEnvelope.isPending || updateEnvelope.isPending;

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setFormError(null);

    let allocationMinor: number;
    let weeklyCapMinor: number | undefined;
    let monthlyCapMinor: number | undefined;
    try {
      allocationMinor = toMinor(allocation);
      weeklyCapMinor = optionalMinor(weeklyCap);
      monthlyCapMinor = optionalMinor(monthlyCap);
    } catch {
      setFormError(t("envelopes.invalidAmount"));
      return;
    }

    try {
      if (isEdit && envelope) {
        const body: EnvelopeUpdateRequest = {
          name: name.trim(),
          icon: icon.trim() || null,
          is_reserve: isReserve,
          allocation_minor_units: allocationMinor,
          weekly_cap_minor_units: weeklyCapMinor,
          monthly_cap_minor_units: monthlyCapMinor,
        };
        await updateEnvelope.mutateAsync({ id: envelope.id, body });
      } else {
        const body: EnvelopeCreateRequest = {
          name: name.trim(),
          icon: icon.trim() || null,
          is_reserve: isReserve,
          allocation_minor_units: allocationMinor,
          weekly_cap_minor_units: weeklyCapMinor,
          monthly_cap_minor_units: monthlyCapMinor,
        };
        await createEnvelope.mutateAsync(body);
      }
      onOpenChange(false);
    } catch (err) {
      setFormError(
        err instanceof ApiError ? err.message : t("envelopes.genericError"),
      );
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {isEdit ? t("envelopes.editTitle") : t("envelopes.createTitle")}
          </DialogTitle>
          <DialogDescription>{t("envelopes.formSubtitle")}</DialogDescription>
        </DialogHeader>

        <form onSubmit={onSubmit} className="flex flex-col gap-4" noValidate>
          {formError && (
            <p
              role="alert"
              className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive"
            >
              {formError}
            </p>
          )}

          <Field label={t("envelopes.nameLabel")}>
            <Input
              name="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={t("envelopes.namePlaceholder")}
              required
            />
          </Field>

          <Field label={t("envelopes.iconLabel")}>
            <Input
              name="icon"
              value={icon}
              onChange={(e) => setIcon(e.target.value)}
              placeholder={t("envelopes.iconPlaceholder")}
            />
          </Field>

          <Field label={t("envelopes.allocationFieldLabel")}>
            <Input
              name="allocation"
              inputMode="numeric"
              value={allocation}
              onChange={(e) => setAllocation(e.target.value)}
              placeholder="0"
            />
          </Field>

          <div className="grid grid-cols-2 gap-3">
            <Field label={t("envelopes.weeklyCapLabel")}>
              <Input
                name="weeklyCap"
                inputMode="numeric"
                value={weeklyCap}
                onChange={(e) => setWeeklyCap(e.target.value)}
                placeholder={t("envelopes.optional")}
              />
            </Field>
            <Field label={t("envelopes.monthlyCapLabel")}>
              <Input
                name="monthlyCap"
                inputMode="numeric"
                value={monthlyCap}
                onChange={(e) => setMonthlyCap(e.target.value)}
                placeholder={t("envelopes.optional")}
              />
            </Field>
          </div>

          <label className="flex items-center gap-3 text-sm text-foreground">
            <input
              type="checkbox"
              name="isReserve"
              checked={isReserve}
              onChange={(e) => setIsReserve(e.target.checked)}
              className="h-4 w-4 accent-primary"
            />
            <span>{t("envelopes.reserveCheckbox")}</span>
          </label>
          <p className="-mt-2 text-xs text-muted-foreground">
            {t("envelopes.reserveHint")}
          </p>

          <div className="mt-2 flex justify-end gap-3">
            <Button
              type="button"
              variant="ghost"
              onClick={() => onOpenChange(false)}
            >
              {t("envelopes.cancel")}
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? t("envelopes.saving") : t("envelopes.save")}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

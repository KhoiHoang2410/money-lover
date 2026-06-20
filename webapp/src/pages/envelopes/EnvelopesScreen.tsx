import { useState } from "react";
import { useTranslation } from "react-i18next";
import { Plus, Sparkles, CalendarClock, Pencil, Trash2 } from "lucide-react";
import type { Client } from "openapi-fetch";
import type { paths, Envelope, MoneyMinorUnits } from "@/api/types";
import { apiClient } from "@/api/client";
import { formatMoney } from "@/lib/money";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { useEnvelopes } from "./useEnvelopes";
import { EnvelopeFormDialog } from "./EnvelopeFormDialog";
import { DeleteEnvelopeDialog } from "./DeleteEnvelopeDialog";
import { StarterEnvelopesDialog } from "./StarterEnvelopesDialog";
import { AllocationTemplateDialog } from "./AllocationTemplateDialog";

interface EnvelopesScreenProps {
  /** Injectable for tests; defaults to the real typed client. */
  client?: Client<paths>;
}

// Typed nulls keep the i18n copy-scanner off TS generics in .tsx (see LoginScreen).
type FormTarget = { envelope?: Envelope } | null;
const NO_FORM: FormTarget = null;
const NO_DELETE_TARGET: Envelope | null = null;

function Figure({
  label,
  money,
  negativeWhenBelowZero = false,
}: {
  label: string;
  money: MoneyMinorUnits;
  negativeWhenBelowZero?: boolean;
}) {
  // Tone is a presentation cue from the API-provided sign — no client math.
  const overspent = negativeWhenBelowZero && money.amount_minor < 0;
  return (
    <div className="flex flex-col gap-0.5">
      <span className="text-xs text-muted-foreground">{label}</span>
      <span
        className={cn(
          "text-sm font-semibold tabular-nums text-foreground",
          overspent && "text-destructive",
        )}
      >
        {formatMoney(money)}
      </span>
    </div>
  );
}

function EnvelopeCard({
  envelope,
  onEdit,
  onDelete,
}: {
  envelope: Envelope;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const { t } = useTranslation();
  return (
    <li
      data-testid={`envelope-${envelope.id}`}
      className={cn(
        "flex flex-col gap-4 rounded-lg border border-border bg-card p-5",
        envelope.is_reserve && "border-primary/50 bg-primary/5 ring-1 ring-primary/30",
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="text-2xl" aria-hidden="true">
            {envelope.icon ?? "✉️"}
          </span>
          <div className="flex flex-col">
            <span className="font-semibold text-foreground">
              {envelope.name}
            </span>
            {envelope.is_reserve && (
              <span className="mt-0.5 w-fit rounded-full bg-primary/15 px-2 py-0.5 text-xs font-semibold text-primary">
                {t("envelopes.reserveBadge")}
              </span>
            )}
          </div>
        </div>
        <div className="flex gap-1">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            aria-label={t("envelopes.editAria", { name: envelope.name })}
            onClick={onEdit}
          >
            <Pencil className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            aria-label={t("envelopes.deleteAria", { name: envelope.name })}
            onClick={onDelete}
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <Figure label={t("envelopes.allocationLabel")} money={envelope.allocation} />
        <Figure label={t("envelopes.spentLabel")} money={envelope.spent} />
        <Figure
          label={t("envelopes.remainingLabel")}
          money={envelope.remaining}
          negativeWhenBelowZero
        />
      </div>
    </li>
  );
}

export function EnvelopesScreen({ client = apiClient }: EnvelopesScreenProps) {
  const { t } = useTranslation();
  const { data: envelopes, isPending, isError, refetch } = useEnvelopes(client);

  const [formState, setFormState] = useState(NO_FORM);
  const [starterOpen, setStarterOpen] = useState(false);
  const [templateOpen, setTemplateOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(NO_DELETE_TARGET);

  return (
    <div className="flex flex-col gap-6">
      <header className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{t("envelopes.title")}</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {t("envelopes.subtitle")}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button
            type="button"
            variant="secondary"
            onClick={() => setStarterOpen(true)}
          >
            <Sparkles className="h-4 w-4" />
            {t("envelopes.starterButton")}
          </Button>
          <Button
            type="button"
            variant="secondary"
            onClick={() => setTemplateOpen(true)}
          >
            <CalendarClock className="h-4 w-4" />
            {t("envelopes.templateButton")}
          </Button>
          <Button type="button" onClick={() => setFormState({})}>
            <Plus className="h-4 w-4" />
            {t("envelopes.newEnvelope")}
          </Button>
        </div>
      </header>

      {isPending && (
        <p className="rounded-lg bg-card p-7 text-sm text-muted-foreground">
          {t("envelopes.loading")}
        </p>
      )}

      {isError && (
        <section className="rounded-lg bg-card p-7">
          <h2 className="text-lg font-bold text-destructive">
            {t("envelopes.errorTitle")}
          </h2>
          <p className="mt-2 text-sm text-muted-foreground">
            {t("envelopes.errorBody")}
          </p>
          <Button
            type="button"
            variant="outline"
            className="mt-4"
            onClick={() => refetch()}
          >
            {t("envelopes.retry")}
          </Button>
        </section>
      )}

      {!isPending && !isError && envelopes.length === 0 && (
        <section className="rounded-lg bg-card p-7 text-center">
          <h2 className="text-lg font-bold">{t("envelopes.emptyTitle")}</h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-muted-foreground">
            {t("envelopes.emptyBody")}
          </p>
          <div className="mt-4 flex justify-center gap-2">
            <Button type="button" onClick={() => setFormState({})}>
              {t("envelopes.newEnvelope")}
            </Button>
            <Button
              type="button"
              variant="secondary"
              onClick={() => setStarterOpen(true)}
            >
              {t("envelopes.starterButton")}
            </Button>
          </div>
        </section>
      )}

      {!isPending && !isError && envelopes.length > 0 && (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {envelopes.map((envelope) => (
            <EnvelopeCard
              key={envelope.id}
              envelope={envelope}
              onEdit={() => setFormState({ envelope })}
              onDelete={() => setDeleteTarget(envelope)}
            />
          ))}
        </ul>
      )}

      {formState && (
        <EnvelopeFormDialog
          // Remount per target so the form resets to the right defaults.
          key={formState.envelope?.id ?? "new"}
          open
          onOpenChange={(open) => !open && setFormState(null)}
          client={client}
          envelope={formState.envelope}
        />
      )}

      {deleteTarget && (
        <DeleteEnvelopeDialog
          open
          onOpenChange={(open) => !open && setDeleteTarget(null)}
          client={client}
          envelope={deleteTarget}
        />
      )}

      <StarterEnvelopesDialog
        open={starterOpen}
        onOpenChange={setStarterOpen}
        client={client}
        existing={envelopes ?? []}
      />

      <AllocationTemplateDialog
        open={templateOpen}
        onOpenChange={setTemplateOpen}
        client={client}
      />
    </div>
  );
}

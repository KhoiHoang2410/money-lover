import { useState } from "react";
import { useTranslation } from "react-i18next";
import type { Client } from "openapi-fetch";
import type { paths, Envelope } from "@/api/types";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { ApiError } from "@/auth/api-error";
import { useSeedStarterEnvelopes } from "./useEnvelopes";
import { STARTER_ENVELOPES, normalizeName } from "./starter-set";

const NO_ERROR: string | null = null;

interface StarterEnvelopesDialogProps {
  client: Client<paths>;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  existing: Envelope[];
}

export function StarterEnvelopesDialog({
  open,
  onOpenChange,
  client,
  existing,
}: StarterEnvelopesDialogProps) {
  const { t } = useTranslation();
  const seed = useSeedStarterEnvelopes(client);
  const [error, setError] = useState(NO_ERROR);

  const existingNames = new Set(existing.map((e) => normalizeName(e.name)));
  // The designated Reserve only becomes the Reserve when the user has none yet.
  const hasReserve = existing.some((e) => e.is_reserve);

  async function onSeed() {
    setError(null);
    try {
      await seed.mutateAsync();
      onOpenChange(false);
    } catch (err) {
      setError(
        err instanceof ApiError ? err.message : t("envelopes.genericError"),
      );
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t("envelopes.starterTitle")}</DialogTitle>
          <DialogDescription>
            {t("envelopes.starterSubtitle")}
          </DialogDescription>
        </DialogHeader>

        {error && (
          <p
            role="alert"
            className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive"
          >
            {error}
          </p>
        )}

        <ul className="flex flex-col gap-2">
          {STARTER_ENVELOPES.map((item) => {
            const alreadyAdded = existingNames.has(normalizeName(item.name));
            const willBeReserve = item.isReserve === true && !hasReserve;
            return (
              <li
                key={item.name}
                data-testid={`starter-${item.name}`}
                aria-disabled={alreadyAdded}
                className={cn(
                  "flex items-center gap-3 rounded-lg border border-border bg-card px-4 py-2.5",
                  alreadyAdded && "opacity-50",
                )}
              >
                <span className="text-lg" aria-hidden="true">
                  {item.icon}
                </span>
                <span className="font-medium text-foreground">{item.name}</span>
                {willBeReserve && (
                  <span className="rounded-full bg-primary/15 px-2 py-0.5 text-xs font-semibold text-primary">
                    {t("envelopes.reserveBadge")}
                  </span>
                )}
                {alreadyAdded && (
                  <span className="ml-auto text-xs text-muted-foreground">
                    {t("envelopes.starterExisting")}
                  </span>
                )}
              </li>
            );
          })}
        </ul>

        <div className="mt-2 flex justify-end gap-3">
          <Button
            type="button"
            variant="ghost"
            onClick={() => onOpenChange(false)}
          >
            {t("envelopes.cancel")}
          </Button>
          <Button type="button" onClick={onSeed} disabled={seed.isPending}>
            {seed.isPending ? t("envelopes.seeding") : t("envelopes.seed")}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

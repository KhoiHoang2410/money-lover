import { useState } from "react";
import { useTranslation } from "react-i18next";
import type { Client } from "openapi-fetch";
import type { paths } from "@/api/types";
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
import { useApplyAllocationTemplate } from "./useEnvelopes";
import { currentMonth } from "./month";

const NO_ERROR: string | null = null;

interface AllocationTemplateDialogProps {
  client: Client<paths>;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AllocationTemplateDialog({
  open,
  onOpenChange,
  client,
}: AllocationTemplateDialogProps) {
  const { t } = useTranslation();
  const apply = useApplyAllocationTemplate(client);
  const [month, setMonth] = useState(currentMonth());
  const [error, setError] = useState(NO_ERROR);

  async function onApply() {
    setError(null);
    try {
      // No `allocations` → the API seeds the month from the saved defaults.
      await apply.mutateAsync({ month });
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
          <DialogTitle>{t("envelopes.templateTitle")}</DialogTitle>
          <DialogDescription>
            {t("envelopes.templateSubtitle")}
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

        <label className="flex flex-col gap-1.5 text-sm font-medium text-foreground">
          <span>{t("envelopes.monthLabel")}</span>
          <Input
            type="month"
            name="month"
            value={month}
            onChange={(e) => setMonth(e.target.value)}
          />
        </label>

        <div className="mt-2 flex justify-end gap-3">
          <Button
            type="button"
            variant="ghost"
            onClick={() => onOpenChange(false)}
          >
            {t("envelopes.cancel")}
          </Button>
          <Button type="button" onClick={onApply} disabled={apply.isPending}>
            {apply.isPending ? t("envelopes.applying") : t("envelopes.apply")}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

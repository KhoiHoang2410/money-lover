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
import { ApiError } from "@/auth/api-error";
import { useDeleteEnvelope } from "./useEnvelopes";

const NO_ERROR: string | null = null;

interface DeleteEnvelopeDialogProps {
  client: Client<paths>;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  envelope: Envelope;
}

export function DeleteEnvelopeDialog({
  open,
  onOpenChange,
  client,
  envelope,
}: DeleteEnvelopeDialogProps) {
  const { t } = useTranslation();
  const deleteEnvelope = useDeleteEnvelope(client);
  const [error, setError] = useState(NO_ERROR);

  async function onConfirm() {
    setError(null);
    try {
      await deleteEnvelope.mutateAsync(envelope.id);
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
          <DialogTitle>{t("envelopes.deleteTitle")}</DialogTitle>
          <DialogDescription>
            {t("envelopes.deleteConfirm", { name: envelope.name })}
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

        <div className="mt-2 flex justify-end gap-3">
          <Button
            type="button"
            variant="ghost"
            onClick={() => onOpenChange(false)}
          >
            {t("envelopes.cancel")}
          </Button>
          <Button
            type="button"
            variant="destructive"
            onClick={onConfirm}
            disabled={deleteEnvelope.isPending}
          >
            {deleteEnvelope.isPending
              ? t("envelopes.deleting")
              : t("envelopes.confirmDelete")}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

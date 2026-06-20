import {
  useMutation,
  useQuery,
  useQueryClient,
  type UseMutationResult,
} from "@tanstack/react-query";
import type { Client } from "openapi-fetch";
import type {
  paths,
  Envelope,
  EnvelopeCreateRequest,
  EnvelopeUpdateRequest,
  AllocationTemplateRequest,
} from "@/api/types";
import { ApiError, toApiError } from "@/auth/api-error";

/*
 * Server-state surface for Envelopes (ADR-0018). Every request goes through the
 * typed client; allocation/spent/remaining are read straight off the API
 * (BudgetEngine) — the web client does no money math. Each mutation invalidates
 * the one ["envelopes"] cache key so the list re-reads the canonical figures.
 */
export const ENVELOPES_KEY = ["envelopes"] as const;

export function useEnvelopes(client: Client<paths>) {
  return useQuery({
    queryKey: ENVELOPES_KEY,
    queryFn: async (): Promise<Envelope[]> => {
      const { data, error } = await client.GET("/api/envelopes");
      if (error || !data) throw toApiError(error);
      return data.envelopes;
    },
    retry: false,
  });
}

function useInvalidateEnvelopes() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: ENVELOPES_KEY });
}

export function useCreateEnvelope(
  client: Client<paths>,
): UseMutationResult<Envelope, ApiError, EnvelopeCreateRequest> {
  const invalidate = useInvalidateEnvelopes();
  return useMutation({
    mutationFn: async (body: EnvelopeCreateRequest): Promise<Envelope> => {
      const { data, error } = await client.POST("/api/envelopes", { body });
      if (error || !data) throw toApiError(error);
      return data;
    },
    onSuccess: () => invalidate(),
  });
}

export interface UpdateEnvelopeArgs {
  id: number;
  body: EnvelopeUpdateRequest;
}

export function useUpdateEnvelope(
  client: Client<paths>,
): UseMutationResult<Envelope, ApiError, UpdateEnvelopeArgs> {
  const invalidate = useInvalidateEnvelopes();
  return useMutation({
    mutationFn: async ({ id, body }: UpdateEnvelopeArgs): Promise<Envelope> => {
      const { data, error } = await client.PATCH("/api/envelopes/{id}", {
        params: { path: { id } },
        body,
      });
      if (error || !data) throw toApiError(error);
      return data;
    },
    onSuccess: () => invalidate(),
  });
}

export function useDeleteEnvelope(
  client: Client<paths>,
): UseMutationResult<void, ApiError, number> {
  const invalidate = useInvalidateEnvelopes();
  return useMutation({
    mutationFn: async (id: number): Promise<void> => {
      const { error } = await client.DELETE("/api/envelopes/{id}", {
        params: { path: { id } },
      });
      if (error) throw toApiError(error);
    },
    onSuccess: () => invalidate(),
  });
}

export function useSeedStarterEnvelopes(
  client: Client<paths>,
): UseMutationResult<Envelope[], ApiError, void> {
  const invalidate = useInvalidateEnvelopes();
  return useMutation({
    mutationFn: async (): Promise<Envelope[]> => {
      const { data, error } = await client.POST("/api/starter_envelopes", {});
      if (error || !data) throw toApiError(error);
      return data.envelopes;
    },
    onSuccess: () => invalidate(),
  });
}

export function useApplyAllocationTemplate(
  client: Client<paths>,
): UseMutationResult<Envelope[], ApiError, AllocationTemplateRequest> {
  const invalidate = useInvalidateEnvelopes();
  return useMutation({
    mutationFn: async (
      body: AllocationTemplateRequest,
    ): Promise<Envelope[]> => {
      const { data, error } = await client.POST("/api/allocation_template", {
        body,
      });
      if (error || !data) throw toApiError(error);
      return data.envelopes;
    },
    onSuccess: () => invalidate(),
  });
}

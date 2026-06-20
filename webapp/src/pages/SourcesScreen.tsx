import { useQuery } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import type { Client } from "openapi-fetch";
import type { paths } from "@/api/types";
import { apiClient } from "@/api/client";
import { groupSourcesByKind } from "@/lib/sources";
import { SourceListItem } from "@/components/sources/SourceListItem";

interface SourcesScreenProps {
  /** Injectable for tests; defaults to the real typed client. */
  client?: Client<paths>;
}

/*
 * Sources list (issue 05, read-only): reads GET /api/sources through the typed
 * client and renders the caller's Accounts, Credit cards, and Holdings grouped
 * by kind. Loading / empty / error states are explicit. CRUD lands in issue 06.
 */
export function SourcesScreen({ client = apiClient }: SourcesScreenProps) {
  const { t } = useTranslation();

  const { data, isPending, isError } = useQuery({
    queryKey: ["sources"],
    queryFn: async () => {
      const { data, error } = await client.GET("/api/sources");
      if (error) throw new Error("sources request failed");
      return data;
    },
    retry: false,
  });

  const groups = data ? groupSourcesByKind(data.sources) : [];

  return (
    <div className="flex flex-col gap-6">
      <header>
        <h1 className="text-2xl font-bold">{t("sources.title")}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {t("sources.subtitle")}
        </p>
      </header>

      {isPending && (
        <p className="rounded-lg bg-card p-5 text-sm text-muted-foreground">
          {t("sources.loading")}
        </p>
      )}

      {isError && (
        <p className="rounded-lg bg-card p-5 text-sm text-destructive">
          {t("sources.error")}
        </p>
      )}

      {!isPending && !isError && groups.length === 0 && (
        <p className="rounded-lg bg-card p-5 text-sm text-muted-foreground">
          {t("sources.empty")}
        </p>
      )}

      {groups.map((group) => (
        <section key={group.kind} className="flex flex-col gap-3">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            {t(`sources.group.${group.kind}`)}
          </h2>
          <ul className="flex flex-col gap-2">
            {group.sources.map((source) => (
              <li key={source.id}>
                <SourceListItem source={source} />
              </li>
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}

import { useTranslation } from "react-i18next";

interface PlaceholderScreenProps {
  /** nav key (e.g. "sources") — titles the section and its "coming soon" copy. */
  sectionKey: string;
}

// Reusable stub for IA sections not yet built in this wave. Keeps the shell's
// nav fully navigable (every link lands somewhere) while features land later.
export function PlaceholderScreen({ sectionKey }: PlaceholderScreenProps) {
  const { t } = useTranslation();
  return (
    <section className="rounded-lg bg-card p-7">
      <h2 className="text-lg font-bold">{t(`nav.${sectionKey}`)}</h2>
      <p className="mt-2 text-sm text-muted-foreground">
        {t("shell.sectionComingSoon")}
      </p>
    </section>
  );
}

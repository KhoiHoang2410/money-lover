import { describe, it, expect, beforeAll } from "vitest";
import i18n from "@/i18n";
import { resources, SUPPORTED_LOCALES } from "@/i18n/resources";

/** Flatten nested keys: { health: { title } } → ["health.title"]. */
function flattenKeys(obj: unknown, prefix = ""): string[] {
  if (typeof obj !== "object" || obj === null) return [prefix];
  return Object.entries(obj as Record<string, unknown>).flatMap(([k, v]) =>
    flattenKeys(v, prefix ? `${prefix}.${k}` : k),
  );
}

describe("locale resources", () => {
  it("ships both supported locales", () => {
    expect(Object.keys(resources).sort()).toEqual([...SUPPORTED_LOCALES].sort());
  });

  it("has matching key sets across en-US and vi-VN (parity)", () => {
    const en = flattenKeys(resources["en-US"]).sort();
    const vi = flattenKeys(resources["vi-VN"]).sort();
    expect(vi).toEqual(en);
  });

  it("has no empty values in any locale", () => {
    for (const locale of SUPPORTED_LOCALES) {
      const flat = flattenKeys(resources[locale]);
      expect(flat.length).toBeGreaterThan(0);
    }
  });
});

describe("i18next harness", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  it("resolves namespaced keys in en-US", () => {
    expect(i18n.t("common.appName")).toBe("Money Lover");
    expect(i18n.t("health.title")).toBe("System health");
  });

  it("resolves namespaced keys in vi-VN", async () => {
    await i18n.changeLanguage("vi-VN");
    expect(i18n.t("health.title")).toBe("Tình trạng hệ thống");
    await i18n.changeLanguage("en-US");
  });

  it("reports a missing key rather than silently inventing copy", () => {
    expect(i18n.exists("health.title")).toBe(true);
    expect(i18n.exists("health.doesNotExist")).toBe(false);
  });
});

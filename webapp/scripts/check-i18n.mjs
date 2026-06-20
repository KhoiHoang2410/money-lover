#!/usr/bin/env node
/*
 * i18n guardrail (PRD i18n; issue #108 CI). Two checks:
 *
 *   1. Key parity — every en-US YAML key exists in vi-VN and vice versa.
 *   2. No hard-coded copy — app JSX must route fixed strings through t(...),
 *      never raw `>Some text<` literals.
 *
 * Vendored Radix/shadcn primitives under src/components/ui/ are generic library
 * code (e.g. an sr-only "Close") and are excluded from the copy scan.
 */
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { parse } from "yaml";

const root = fileURLToPath(new URL("..", import.meta.url));
const localesDir = join(root, "src/i18n/locales");
const srcDir = join(root, "src");

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

let failed = false;
const fail = (msg) => {
  failed = true;
  console.error(`${RED}✗${RESET} ${msg}`);
};

function walk(dir, predicate) {
  const out = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) out.push(...walk(full, predicate));
    else if (predicate(full)) out.push(full);
  }
  return out;
}

function flatten(obj, prefix = "") {
  if (obj === null || typeof obj !== "object") return [prefix];
  return Object.entries(obj).flatMap(([k, v]) =>
    flatten(v, prefix ? `${prefix}.${k}` : k),
  );
}

// ── Check 1: key parity ───────────────────────────────────────────────────
const locales = readdirSync(localesDir).filter((d) =>
  statSync(join(localesDir, d)).isDirectory(),
);

const keysByLocale = {};
for (const locale of locales) {
  const files = walk(join(localesDir, locale), (f) => f.endsWith(".yaml"));
  const merged = {};
  for (const file of files) {
    Object.assign(merged, parse(readFileSync(file, "utf8")) ?? {});
  }
  keysByLocale[locale] = new Set(flatten(merged));
}

if (locales.length < 2) {
  fail(`expected at least 2 locales, found: ${locales.join(", ") || "none"}`);
} else {
  const [base, ...rest] = locales;
  for (const other of rest) {
    const missingInOther = [...keysByLocale[base]].filter(
      (k) => !keysByLocale[other].has(k),
    );
    const missingInBase = [...keysByLocale[other]].filter(
      (k) => !keysByLocale[base].has(k),
    );
    if (missingInOther.length) {
      fail(`${other} is missing keys present in ${base}: ${missingInOther.join(", ")}`);
    }
    if (missingInBase.length) {
      fail(`${base} is missing keys present in ${other}: ${missingInBase.join(", ")}`);
    }
  }
  if (!failed) {
    console.log(
      `${GREEN}✓${RESET} i18n key parity: ${keysByLocale[base].size} keys match across ${locales.join(", ")}`,
    );
  }
}

// ── Check 2: no hard-coded JSX copy ───────────────────────────────────────
const appFiles = walk(
  srcDir,
  (f) =>
    f.endsWith(".tsx") &&
    !f.endsWith(".test.tsx") &&
    !f.includes(`${join("components", "ui")}`),
);

// Matches `>Some text<` where the text holds a real word and no `{ } < >`,
// i.e. raw JSX copy that bypassed t(). Brace expressions like `{t("…")}` are
// excluded because they contain `{`.
const jsxCopy = />\s*([^<>{}]*?[A-Za-z]{2,}[^<>{}]*?)\s*</g;

for (const file of appFiles) {
  const src = readFileSync(file, "utf8")
    .replace(/\/\*[\s\S]*?\*\//g, "") // strip block comments
    .replace(/^\s*\/\/.*$/gm, ""); // strip line comments
  let match;
  while ((match = jsxCopy.exec(src)) !== null) {
    const text = match[1].trim();
    if (!text) continue;
    const line = src.slice(0, match.index).split("\n").length;
    fail(
      `hard-coded copy in ${relative(root, file)}:${line} → "${text}" (use t("<page>.<textName>"))`,
    );
  }
}

if (!failed) {
  console.log(`${GREEN}✓${RESET} no hard-coded JSX copy in app components`);
  console.log(`${GREEN}✓ i18n checks passed${RESET}`);
  process.exit(0);
} else {
  console.error(`${RED}i18n checks failed${RESET}`);
  process.exit(1);
}

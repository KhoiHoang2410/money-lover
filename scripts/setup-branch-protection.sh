#!/usr/bin/env bash
#
# Apply the committed branch-protection ruleset to `main`.
#
# GitHub branch protection is a repo *setting*, not something a workflow can
# commit — so we keep the desired state in .github/rulesets/main.json and apply
# it with this script. Run it once (and again after editing the JSON):
#
#     ./scripts/setup-branch-protection.sh
#
# It is idempotent: a ruleset named "main branch protection" is updated in place
# if it already exists, otherwise created. Requires the `gh` CLI authenticated
# as a repo admin (`gh auth login`).
#
# Effect: merging into `main` requires an open PR plus three passing checks —
# `build`, `unit-tests`, `ui-smoke` — with the branch up to date. The nightly
# `ui-full` job never runs on PRs, so it is intentionally NOT required. See
# docs/adr/0011-tiered-ui-tests.md.

set -euo pipefail

RULESET_FILE="$(cd "$(dirname "$0")/.." && pwd)/.github/rulesets/main.json"
RULESET_NAME="$(jq -r .name "$RULESET_FILE")"

# Resolve the repo (owner/name) from the current gh context.
REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
echo "Repo: $REPO"
echo "Ruleset: $RULESET_NAME"

# Find an existing ruleset with the same name (repo-level rulesets).
existing_id="$(gh api "repos/${REPO}/rulesets" --jq \
  ".[] | select(.name == \"${RULESET_NAME}\") | .id" 2>/dev/null | head -n1 || true)"

if [ -n "${existing_id}" ]; then
  echo "Updating existing ruleset #${existing_id}…"
  gh api -X PUT "repos/${REPO}/rulesets/${existing_id}" \
    --input "$RULESET_FILE" >/dev/null
  echo "✅ Updated ruleset #${existing_id}"
else
  echo "Creating ruleset…"
  new_id="$(gh api -X POST "repos/${REPO}/rulesets" \
    --input "$RULESET_FILE" --jq .id)"
  echo "✅ Created ruleset #${new_id}"
fi

echo
echo "Required to merge into the default branch:"
echo "  • an open pull request"
echo "  • passing checks: build, unit-tests, ui-smoke"
echo "  • branch up to date with the base"

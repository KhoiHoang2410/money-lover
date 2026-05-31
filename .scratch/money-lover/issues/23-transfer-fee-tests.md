# 23 — Transfer / Fee unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/05`, `06`)

## What to build
`TransferEngine` tests for cross-currency Fee computation and transfer semantics. Fee = amount out × rate − amount in, using the manually entered rate (not the fetched valuation rate, per ADR-0003).

## Acceptance criteria
- [ ] Fee computed correctly from out/in/rate (05-01).
- [ ] Transfer uses the entered rate, ignoring any differing fetched valuation rate (05-04).
- [ ] Transfer is not spending — no Envelope effect; net worth changes only by the Fee (05-03).
- [ ] Negative/zero Fee (favorable rate) handled without crash, or rejected per the spec — assert the chosen rule (05-05).
- [ ] Same-currency transfer and credit-card bill payment net to zero on net worth (06-01/06-02).

## Blocked by
- 17 — Test fixtures & builders

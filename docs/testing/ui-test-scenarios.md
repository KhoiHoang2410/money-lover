# Money Lover — Customer Test Scenarios

Written from the point of view of **the owner** (the single user the app is built for, per the PRD):
multi-currency money across VPBank/VIB/MBBank, Wise (SGD/USD), Cash, Gold, Stock, two credit
cards; budgets via Envelopes; three savings Goals. These scenarios drive the seeded **sample data**
(`MoneyLover/Debug/SampleData.swift`) and are the source of truth for the automated suite under
`MoneyLoverUITests/`.

Each scenario: **Goal → Steps → Expected**. The "Automated" line names the test that encodes it.

### Which tier runs each test (ADR-0011)

Tests split into **Smoke** (the curated PR gate, ≤5 min — `Smoke.xctestplan`) and **Full** (everything, nightly — `Full.xctestplan`). The slow cross-tab + relaunch persistence guards are deliberately Full-only:

| Scenario | Smoke (PR gate) | Full-only (nightly) |
|---|---|---|
| S1 Navigation | `testAllTabsReachable`, `testSeedDataPresent` | — |
| S2 Privacy | `testAmountsCensoredByDefault`, `testToggleRevealsAmounts` | — |
| S3 Account history | `testTapAccountOpensHistory`, `testTapGoalAssetOpensDetail` | — |
| S4 Cash expense | `testAddExpenseSavesAndReturns`, `testSaveDisabledWithoutAmount` | `testExpensePropagatesAcrossTabsAndSurvivesRelaunch` |
| S5 Cross-currency transfer | — | `testCrossCurrencyTransferComputesFeeAndSaves`, `…ChangesNetWorthByFee` |
| S6 Reconcile | `testEnteringRealBalanceEnablesRecord` | `testReconcileAdjustsBalanceAndNetWorth` |
| S7 Fund goal | `testContributeToGoal` | `testContributionKeepsNetWorthAndReducesFundingAccount` |
| Income / Transfer / Envelope / Backfill / Source freshness / Amount grouping / Config areas / Voice-removed | — | all of `IncomeUITests`, `TransferUITests`, `EnvelopesUITests`, `BackfillUITests`, `SourceFreshnessUITests`, `AmountGroupingUITests`, `ConfigUITests`, `VoiceRemovedUITests` |

Rule for new tests: **Full-only by default**; promote to Smoke only if core-flow + single-launch + fast + budget holds (`docs/guidelines/testing.md` § Test tiers).

Seed snapshot the scenarios assume:
- Accounts: MBBank, VPBank, VIB, Wise SGD, Wise USD, Cash, Savings
- Holdings: Gold SJC (5 chỉ), FPT (500 shares)
- Credit cards: VPBank Credit, MBBank Credit
- Envelopes: Food, Rent, Transport, Fun, Reserve (default)
- Goals: House (~12%), Car (~20%), Travel (~79%)

---

## S1 — Land in the app and reach every section
**Goal:** As the owner, open the app and confirm all five areas are reachable.
**Steps:**
1. Launch the app (seeded).
2. Tap each tab: Overview, Goals, Calendar, Add, Config.
3. Return to Overview.
**Expected:** Each tab presents its screen without crashing; Overview shows the net-worth hero.
**Automated:** `NavigationUITests.testAllTabsReachable`, `testSeedDataPresent`.

## S2 — Net worth is private by default
**Goal:** As the owner, I don't want balances exposed to shoulder-surfers (PRD #54).
**Steps:**
1. Open Overview.
2. Read the net-worth hero.
3. Tap the eye (Show amounts) toggle.
**Expected:** On open, the amount is censored (`••••••`, VoiceOver "hidden"). After the toggle it
reveals a real VND figure; toggling again re-hides it.
**Automated:** `OverviewPrivacyUITests.testAmountsCensoredByDefault`, `testToggleRevealsAmounts`.

## S3 — Inspect one account's history
**Goal:** As the owner, drill into MBBank to see its transactions.
**Steps:**
1. Open Overview.
2. Tap the MBBank account row.
**Expected:** The MBBank Account History screen pushes (title "MBBank") with its transactions.
**Automated:** `OverviewPrivacyUITests.testTapAccountOpensHistory` (was BUG-001, now fixed + guarded).

## S4 — Log a quick cash expense
**Goal:** As the owner, log a 45,000₫ coffee against Food from Cash (PRD #10).
**Steps:**
1. Calendar → floating +.
2. Type 45000 into Amount.
3. From = Cash; Envelope = Food.
4. Tap Save.
**Expected:** Save is enabled only once amount + source are set; saving dismisses back to the Add hub
and the expense reduces Cash / Food remaining.
**Automated:** `AddExpenseUITests.testAddExpenseSavesAndReturns`, `testSaveDisabledWithoutAmount`.

## S5 — Move money across currencies (Wise SGD → VPBank VND)
**Goal:** As the owner, transfer SGD to VND and let the app compute the Fee (PRD #16).
**Steps:**
1. Calendar → floating +.
2. Type = Transfer.
3. From = Wise SGD; To = VPBank — differing currencies reveal the cross-currency fields.
4. Amount out 100; Amount in 1,800,000; Rate 18,500.
5. Tap Save.
**Expected:** A Fee row appears (amount out × rate − amount in); Save enabled only when all three
numbers are present; saving returns to the Add hub.
**Automated:** `CrossCurrencyTransferUITests.testCrossCurrencyTransferComputesFeeAndSaves`.

## S6 — Reconcile a drifted balance
**Goal:** As the owner, correct Cash after forgotten small spends (PRD #40/41).
**Steps:**
1. Config → Update balances.
2. Enter a real Cash balance different from the computed one.
3. Tap Record.
**Expected:** Record is disabled until a real balance differs; once it does, an Adjustment is created
and the screen dismisses.
**Automated:** `ReconcileUITests.testEnteringRealBalanceEnablesRecord`.

## S7 — Fund a goal
**Goal:** As the owner, add 2,000,000₫ to Travel from MBBank (PRD #27, ADR-0007).
**Steps:**
1. Goals tab → tap the Travel ring.
2. Tap "Add money".
3. Amount 2,000,000; From = MBBank.
4. Tap Save.
**Expected:** The contribution sheet saves and dismisses back to the Travel detail; Travel's saved
balance rises and the account drops by the same amount (net worth unchanged).
**Automated:** `GoalContributionUITests.testContributeToGoal`.

---

## Scenarios documented but not yet automated (manual / future)
- **S8 Voice expense** (PRD #35–38): needs on-device Speech + Foundation Models; human-in-the-loop
  per the PRD, so left manual.
- **S9 Month-end sweep** (PRD #22/23): Config → Run month-end sweep; leftovers fold into Reserve.
- **S10 Charts ranges + insufficient-history refusal** (PRD #55/56).
- **S11 Calendar month navigation + per-day net** (PRD #51/59).
- **S12 Rate manual override + staleness** (PRD #44/45).

# Money Lover

Personal finance app for a single owner. Tracks money across multiple accounts and currencies, divides income into buckets, and measures progress toward savings goals. On-device only (see `docs/adr/0001-on-device-only-no-backend.md`).

## Language

### Money sources

**Account**:
A balance held directly in a single currency, read off as one number. The bank accounts (VPBank, VIB, MBBank), Wise balances (SGD, USD), and Cash are Accounts.
_Avoid_: Wallet, source

**Holding**:
Something owned whose value is quantity × market price rather than a fixed balance — Gold and Stock. Requires a valuation to express in money. Created with only an **opening quantity** (e.g. 3 chỉ, 120 shares) — never a money amount. Its live quantity = opening quantity + Σ Buys − Σ Sells (see **Invest**).
_Avoid_: Asset (reserved for the computed total), Investment

**Card**:
A means of paying, not a balance of its own.
_Avoid_: Payment method

**Debit card**:
A Card that draws directly from an Account. Spending on it reduces that Account. Not tracked as a separate entity.

**Credit card**:
A Card that is a Liability. Spending on it increases debt at purchase time; it touches no Account until the bill is paid.
_Avoid_: Credit account

**Liability**:
Money owed. Currently only Credit cards.
_Avoid_: Debt (reserved for the computed total)

### Valuation

**Base currency**:
The single currency every total is expressed in: VND. Accounts in other currencies and all Holdings are converted to it.

**Rate**:
The price used to convert a foreign-currency Account or a Holding into the base currency — an FX rate (SGD/USD→VND), the SJC gold price, or a HOSE stock price. Auto-fetched, cached, with a manual override. See `docs/adr/0003-external-price-fetch-for-valuation.md`.
_Avoid_: Exchange rate (too narrow — also covers gold/stock prices)

### Budgeting

**Envelope**:
A named virtual bucket that income is divided into (e.g. Food, Rent, Fun). Virtual — a claim on money already sitting in Accounts, not a real separate account. Every Expense is assigned to an Envelope, reducing its remaining amount.
_Avoid_: Group, bucket, category

**Allocation**:
The amount of money planned into an Envelope for the month. Envelopes reset to their Allocation at the start of each month.
_Avoid_: Budget, limit

**Allocation template**:
The saved default set of Envelope Allocations, auto-applied at the start of each month and editable for that month. Allocations are independent of any single Income — they plan over total available money, not one paycheck.
_Avoid_: Budget template

**Starter envelopes**:
A single hard-coded set of suggested Envelopes (name + icon, Allocation ₫0) the owner picks from to populate the Envelopes list — wholly or in part. Applied over existing Envelopes, any whose name already matches (case-insensitive, trimmed) is shown disabled. One member is the designated Reserve, which becomes the Reserve only if none exists yet. A one-time seed, distinct from the recurring *Allocation template*.
_Avoid_: Template, preset

**Reserve**:
The single Envelope marked as default. At month-end, each other Envelope's leftover (Allocation − spent) sweeps into the Reserve — positive leftover adds to it, an overspent (negative) Envelope deducts from it. The Reserve accumulates and does not reset.
_Avoid_: Savings, default, surplus

### Goals

**Goal**:
A long-term savings target (house, car, travel) with a name, target amount, a **funding window** (start month → end month), and a funding Schedule. Contributions happen monthly, so the window is month-based — a start and end *month*, not an exact day. A Goal holds a real balance — the accumulated Contributions — and is counted as an Asset in net worth. Money put toward a Goal accumulates and does not reset. (Investing is not a Goal — it is a Holding.)
_Avoid_: Plan, target, target date

**Contribution**:
A dated movement of money from a VND Account into a Goal, recorded as a Transfer (the Account's balance decreases and the Goal's balance increases by the same amount, so net worth is unchanged — one Asset becomes another). VND-only for now — foreign-currency Accounts cannot fund a Goal. A Goal's balance is the sum of its Contributions. See `docs/adr/0007-goals-are-funded-assets.md`.
_Avoid_: Deposit, payment

**Schedule**:
A Goal's planned contributions over time — a list of month → planned amount (e.g. House: Jan–Mar 100M, May 150M, Jul–Sep 100M). Need not be flat or continuous. A Schedule line is a *plan*, distinct from an actual Contribution.

**Expected-by-today**:
The cumulative sum of a Goal's Schedule due up to the current date. A Goal is "% ahead/delay" = actual contributed ÷ Expected-by-today − 1.

**Funded / Pending / Due / Missed**:
The status of a Schedule line, judged cumulatively against total contributed: **Funded** (green) = total contributed so far ≥ the cumulative scheduled amount through that month; **Due** (amber) = the *current* month's cumulative amount is not yet met (still fundable before the month ends); **Missed** (red) = a *past* month whose cumulative amount was never met; **Pending** (gray) = a future month not yet covered. Each unmet line (Due or Missed) carries a **shortfall** — its scheduled amount minus the Contributions allocated to it, where Contributions fill Schedule lines oldest-first.

### Balances and corrections

**Opening balance**:
The amount of an Account or Liability entered once when the app starts tracking it. The anchor for all balance math. (A Holding has no opening money balance — it anchors on an **opening quantity** instead; see **Holding**.)

**Current balance**:
A source's live amount = Opening balance + Σ of its balance-affecting Transactions. Always meant to equal reality.

**Backfill**:
A forgotten past Transaction logged after the fact. It is an ordinary Transaction (it shows on the calendar and in reports), but recording it also restates its source's Opening balance by the offsetting amount, so the Current balance is unchanged — the money already left or arrived before tracking began (ADR-0012).
_Avoid_: Backdated, late entry

**Reconcile**:
The end-of-day/month mode where the owner re-enters each source's real balance. Any difference from the Current balance becomes an Adjustment.
_Avoid_: Sync, refresh

### Advice

**Signal**:
A computed observation about spending or goals — envelope pace (spent vs fraction of month elapsed), projected overspend, a Goal's delay, a shrinking Reserve, an unusually large Expense. Calculated deterministically in Swift, never by a model.

**Recommendation**:
User-facing advice derived from Signals, shown both as an input-time nudge and as a periodic summary. The on-device model only phrases it; the analysis is the Signal. See `docs/adr/0004-rule-based-recommendations.md`.
_Avoid_: Insight, tip

### Net worth

**Asset**:
Computed total value of all Accounts + Holdings + Goal balances, expressed in the base currency. A derived number, not an entity.

**Debt**:
Computed total owed across all Liabilities, in the base currency. Derived, not an entity.

### Transactions

**Expense**:
Money spent. Recorded at purchase time. A credit-card Expense increases that card's Liability; an Account/debit Expense reduces the Account.
_Avoid_: Payment, spend

**Income**:
Money received, increasing an Account.

**Transfer**:
Movement of money between two of the owner's own places, not an Expense or Income. Paying a credit-card bill is a Transfer (Account ↓, Liability ↓). A cross-currency Transfer (e.g. Wise SGD → VPBank VND) records amount out, amount in, and a manually-entered Rate, from which the Fee is computed — it does not use the auto-fetched valuation Rate.
_Avoid_: Move

**Fee**:
The cost of a cross-currency Transfer, computed as (amount out × Rate) − amount in, expressed in the destination currency. Not entered directly.

**Invest**:
A Buy or Sell of a Holding, recorded as a movement between a VND Account and a Holding. **Buy**: an Account pays quantity × unit price and the Holding's quantity increases. **Sell**: the Holding's quantity decreases and the Account receives quantity × unit price. The unit price is the manually-entered *accepted* price actually transacted at — distinct from the auto-fetched valuation Rate. A Holding's live quantity = opening quantity + Σ Buys − Σ Sells (the balance invariant applied to quantity). VND-only; selling more than held is blocked. See `docs/adr/0010-holding-trades-derive-quantity.md`.
_Avoid_: Trade, Investment (the entity stays a Holding)

**Adjustment**:
A Transaction created during Reconcile to absorb the difference between a source's Current balance and its real balance. Carries a description and an Envelope assignment.
_Avoid_: Correction, fix

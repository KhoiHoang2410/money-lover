# Holding quantity is derived from Invest trades, not a stored running total

A **Holding** (gold, stock) is created with only an **opening quantity** — never a money amount. Its live quantity is computed: `opening quantity + Σ Buys − Σ Sells`, exactly as Account balances are `opening + Σ transactions`. Trading a Holding is a new **Invest** transaction kind with a Buy/Sell direction, modeled as a movement between a VND **Account** and the Holding: a **Buy** debits the Account by `quantity × unit price` and raises the Holding's quantity; a **Sell** lowers the quantity and credits the Account `quantity × unit price`. The unit price is the manually-entered *accepted* price actually transacted at — distinct from the auto-fetched valuation **Rate** used to value the Holding for net worth.

We chose a derived quantity so the **single source of truth is the transaction ledger**, matching the app-wide invariant *current = opening + Σ transactions*. Editing or deleting an Invest trade (feat 5) then auto-corrects the Holding's quantity with no stored field to patch, the same way it already auto-corrects Account balances.

Alternatives rejected:
- **Mutate a stored `HoldingInfo.quantity` on each trade, recording the transaction for history only.** Simpler write path, but the quantity becomes a running total that can silently drift from its own history — and editing/deleting a past trade would have to re-derive it anyway, so the stored number buys nothing but a way to be wrong.
- **Treat invested VND as a money balance on the Holding.** Contradicts the Holding definition (value is quantity × market price); it would freeze in the purchase-time price and never reflect market moves.

## Consequences

- `TransactionKind` gains `.invest`; `Transaction` carries the traded quantity and unit price (a Buy/Sell discriminator) so the money side and the quantity side are both reconstructable. `HoldingInfo.quantity` now means **opening quantity**.
- A new quantity engine derives a Holding's live quantity from its opening quantity and the Invest trades touching it; the **Valuator** values `live quantity × price` instead of the stored opening quantity. `BalanceEngine` handles the VND Account side of an Invest (debit on Buy, credit on Sell) so net worth stays honest — one Asset (Account cash) becomes another (Holding units).
- Invest trades are **VND-only**; foreign-currency Accounts cannot trade a Holding yet (no FX in the write path), mirroring Goal Contributions.
- **Selling more units than currently held is blocked** at entry — a Holding's quantity cannot go negative.
- Invest trades appear in calendar and account history (they touch the Account) but are excluded from spending/envelope reports (those filter `kind == .expense`); an Invest carries no Envelope.
- Existing Holdings created with a money opening balance are reinterpreted: their stored quantity is the opening quantity and the prior money opening balance is unused (it never fed the Valuator).

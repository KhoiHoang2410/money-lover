# Goals are funded Assets, not virtual trackers

Funding a Goal moves real money: a Contribution debits a chosen VND **Account** and credits the **Goal**, which holds the accumulated balance. A Goal's balance is the sum of its Contributions and is counted as an **Asset** in net worth, alongside Accounts and Holdings. Net worth is unchanged by a Contribution — one Asset (Account) becomes another (Goal).

The earlier implicit model treated a Goal as a virtual tracker: contributions were standalone numbers that never touched an Account (`ContributionSheet` recorded an amount with no source). That understated nothing only because Goals were excluded from net worth entirely — but it could not answer "where did this money come from?" and made funding feel fake.

We chose funded Assets because the owner actually moves money into savings when funding a Goal; the Account balance must reflect that, and the saved money must still appear in net worth. This keeps the **Current balance = reality** invariant true for the source Account while keeping net worth honest.

Alternatives rejected:
- **Virtual earmark (envelope-style):** Goals don't touch Accounts; money stays put, Goal tracks a claim. Simpler, but the Account balances then overstate spendable money and the owner can't see the transfer actually happened.
- **Sinking fund (money leaves net worth):** funding a Goal lowers net worth. Wrong here — the money is still owned, just earmarked.

## Consequences

- A Contribution is realized as a single **Transfer Transaction**: `kind == .transfer`, `sourceID` = the VND Account, no destination Source, tagged with a new `goalID`. `BalanceEngine` already debits the source and credits nothing when `destinationID` is nil — so no engine change is needed for the Account side.
- The transaction ledger is the **single source of truth** for goal funding. A Goal's balance = Σ amounts of `.transfer` transactions carrying its `goalID`. The previous standalone `ContributionRecord` is removed so the same money can't be counted twice; `GoalRepository.totalContributed` / `contributions(goalID:)` derive from tagged transfers.
- `NetWorthEngine` adds Σ Goal balances to Asset. Net is unchanged per Contribution: source Account ↓, Goal ↑, same amount.
- Goal funding appears automatically in calendar and account history (it's a normal transfer touching the Account) but is excluded from spending/envelope reports (those filter `kind == .expense`).
- Foreign-currency Accounts can't fund a Goal yet (no conversion in the write path) — deferred.
- Withdrawing/redirecting money out of a Goal is not modeled yet (no negative-amount flow).
- Schedule lines remain *plans*; their Funded/Pending/Missed status is derived from actual contributions, cumulatively.

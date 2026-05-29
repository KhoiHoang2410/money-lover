# On-device only, no backend

The app runs entirely on the user's iPhone with all data stored locally — no server, no external API, no account. We chose this because (a) iOS makes automatic transaction capture infeasible for our case anyway: third-party apps cannot read other apps' notifications, cannot read SMS, and have no Apple Pay transaction API; and (b) the only viable automation (SePay/Casso webhooks, bank-email parsing) only captures *incoming* bank transfers — never credit-card spending, which is the user's primary spend — and would require an always-on backend. Given <100 transactions/month, manual + voice entry is sufficient, and staying fully local keeps financial data private and eliminates all hosting cost.

## Consequences

- Transaction entry is manual or voice-driven; there is no bank sync.
- "No backend" means we run no server of our own. The app may still make outbound read-only calls to third-party public endpoints for market data (see ADR-0003). Storage stays fully local.
- Multi-device sync, if ever wanted, would need a deliberate later decision (e.g. iCloud/CloudKit), not an ad-hoc server.

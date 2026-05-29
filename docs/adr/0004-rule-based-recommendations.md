# Rule-based recommendations, LLM only phrases

Spending recommendations ("you're overspending Food", "house Goal is behind") are computed by a deterministic rule engine in Swift — not by an LLM. The on-device Foundation Models model is used only to phrase a computed Signal into friendly text (and even that is optional; a template + icon is the fallback).

We chose this because the ~3B on-device model is explicitly weak at math and multi-step reasoning over data, so trusting it to decide *whether* spending is too high would be unreliable — exactly the kind of correctness a finance app cannot get wrong. The numbers must be right; only the wording benefits from a model.

## Consequences

- Recommendation logic is testable Swift (unit-tested), independent of any model.
- Stays 100% on-device — no cloud LLM. A cloud model (e.g. Claude Haiku) for richer monthly advice is a deliberate future option, not built now.

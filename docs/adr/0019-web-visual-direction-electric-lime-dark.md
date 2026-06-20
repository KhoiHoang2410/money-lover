# Web visual direction: Electric Lime Dark Fintech (diverges from iOS)

The `webapp/` client adopts the **"Electric Lime Dark Fintech"** design language (`docs/design/electric-lime-dark-fintech.md`): a near-black canvas, a single electric-lime accent, large confident money figures, generous rounded cards, selective lime/white "hero" inversion, and minimal lime/white data-viz. This is **intentionally different** from the iOS "Gradient Rings" direction (ADR-0005, pink→yellow, circular rings, light). ADR-0016 establishes that the three apps are different deliveries of one domain, so a per-client look is allowed; the shared layer is the ubiquitous language and the API contract, not the pixels.

## Considered options

- **Electric Lime Dark Fintech, web-native (chosen).** A purpose-built dark dashboard aesthetic that suits the web client's dense, multi-column, desktop-first layout (full-parity v1 includes reports and charts). The brief already exists and is web-oriented. Web and iOS diverge by design.
- **Mirror iOS Gradient Rings (ADR-0005).** Rejected for v1: a pink/yellow, light, mobile-portrait aesthetic adapted to a wide desktop dashboard fits the data-dense surface poorly, and re-interpreting circular-ring motifs for tables/charts is friction for little brand payoff while iOS owns the native-mobile experience.
- **A fresh, third web design system.** Rejected: most effort, discards a ready-made web-suited brief, and adds a third visual language to maintain.

## Consequences

- `docs/design/electric-lime-dark-fintech.md` becomes the committed source of the web design tokens (canvas `#0E0E10`, surface `#1C1C1E`, accent lime `#C9F23B`, off-white hero `#F4F4EF`, muted text `#8A8A8E`, ~20–24px radii, pill controls). The web design tokens live in `webapp/` and are derived from it.
- Web and iOS will not look alike; cross-client visual consistency is explicitly **not** a goal (ADR-0016). Brand coherence rests on shared language and behavior, not shared styling.
- Changing this later means re-skinning every web screen — hence recording it now.
- The "accent inversion" rule (only 2–3 hero elements flip to solid lime/white) is a load-bearing part of the language, not decoration: it directs attention to balances and primary actions. Reviewers should hold new UI to that restraint (a strictly 3-color system).

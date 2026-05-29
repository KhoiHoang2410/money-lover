# Native SwiftUI stack

We build with native SwiftUI (SwiftData for local storage, the Speech framework for voice, the Foundation Models framework for on-device AI parsing, SF Symbols for icons) rather than React Native/Expo or Flutter — despite the owner being a TypeScript/React engineer, not a Swift developer.

The deciding factor: the heart of the app (voice expense entry parsed by Apple's on-device Foundation Models) depends on Apple-only frameworks that are first-class in Swift but only reachable through a fragile community bridge in React Native, and absent entirely in Flutter. Since the architecture is already 100% on-device Apple (see ADR-0001), a cross-platform layer would add friction exactly where the app is most demanding, with no payoff. The Swift learning curve is the accepted cost.

## Consequences

- Local store: SwiftData. Voice: SpeechTranscriber. AI: Foundation Models (`@Generable`). Icons: SF Symbols (+ Phosphor for any missing finance glyphs).
- Testing: Swift Testing (unit) + XCUITest (UI/integration).
- Requires iOS 26+ on an A17 Pro-class device (iPhone 15 Pro+) for on-device AI; the owner's iPhone 15 Pro Max qualifies.

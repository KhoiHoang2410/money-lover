import Foundation

/// App version and build number, read from the bundle's generated Info.plist. The single source
/// of truth is the `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` build settings — never a
/// hard-coded constant that could drift from what actually ships. `bundle` is injectable so the
/// logic is unit-testable without `.main`.
enum AppInfo {
    /// Marketing (semver) version, e.g. `"0.2.0"` — `CFBundleShortVersionString`.
    static func version(bundle: Bundle = .main) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    /// Build number, e.g. `"2"` — `CFBundleVersion`.
    static func build(bundle: Bundle = .main) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    /// User-facing line for the Config footer, e.g. `"Money Lover 0.2.0 (2)"`.
    static func displayString(bundle: Bundle = .main) -> String {
        format(version: version(bundle: bundle), build: build(bundle: bundle))
    }

    /// Pure composer — kept separate from bundle reads so it's deterministically unit-testable.
    static func format(version: String, build: String) -> String {
        "Money Lover \(version) (\(build))"
    }
}

import SwiftUI

/// Temporary placeholder for tabs whose feature slice hasn't landed yet.
struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "hammer.fill",
            description: Text("Coming in a later slice.")
        )
    }
}

#Preview {
    PlaceholderScreen(title: "Overview")
}

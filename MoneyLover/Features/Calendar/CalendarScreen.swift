import SwiftUI

/// The Calendar tab: per-day net grid with month navigation and day detail.
struct CalendarScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: CalendarStore?
    @State private var pickingMonth = false

    var body: some View {
        NavigationStack {
            Group {
                if let store {
                    MonthGrid(store: store, pickingMonth: $pickingMonth)
                } else {
                    ProgressView()
                        .task {
                            let now = Calendar.current.dateComponents([.year, .month], from: .now)
                            let newStore = CalendarStore(
                                repo: TransactionRepository(context: context),
                                year: now.year ?? 2026,
                                month: now.month ?? 1
                            )
                            newStore.load()
                            store = newStore
                        }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: ChartsDestination.charts) {
                        Label("Charts", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .navigationDestination(for: DayRef.self) { ref in
                if let store {
                    DayDetailScreen(store: store, ref: ref)
                }
            }
            .navigationDestination(for: ChartsDestination.self) { _ in
                ChartsScreen()
            }
            .sheet(isPresented: $pickingMonth) {
                if let store {
                    MonthPickerSheet(initialYear: store.year) { year, month in
                        store.year = year
                        store.month = month
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}

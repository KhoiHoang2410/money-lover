import SwiftUI

/// The Calendar tab: per-day net grid with month navigation and day detail. A floating + adds a
/// transaction on the picked day (feat 1); tapping a day-detail row opens it to edit or delete (feat 5).
struct CalendarScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: CalendarStore?
    @State private var inputStore: InputStore?
    @State private var pickingMonth = false
    @State private var sheet: CalendarSheetRoute?

    var body: some View {
        NavigationStack {
            Group {
                if let store {
                    VStack(spacing: 0) {
                        MonthGrid(store: store, pickingMonth: $pickingMonth)
                        CalendarDayDetail(store: store, onEdit: { sheet = .edit($0) })
                    }
                    .overlay(alignment: .bottomTrailing) { addButton }
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
                            let input = InputStore(
                                sources: SourceRepository(context: context),
                                transactions: TransactionRepository(context: context),
                                envelopes: EnvelopeRepository(context: context),
                                goals: GoalRepository(context: context)
                            )
                            input.load()
                            inputStore = input
                        }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: ChartsDestination.charts) {
                        Label("Charts", systemImage: "chart.line.uptrend.xyaxis")
                    }
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
            .sheet(item: $sheet) { route in
                if let inputStore {
                    NavigationStack {
                        switch route {
                        case .add(let date):
                            TransactionForm(store: inputStore, initialDate: date)
                        case .edit(let transaction):
                            TransactionForm(store: inputStore, editing: transaction,
                                            onDelete: { store?.delete(transaction) })
                        }
                    }
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            if let store { sheet = .add(store.prefillDate) }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.heroGradient, in: Circle())
                .shadow(radius: 6, y: 3)
        }
        .padding(Theme.Spacing.xl)
        .accessibilityIdentifier(A11y.Calendar.addTransaction)
        .accessibilityLabel("Add transaction")
    }
}

#Preview {
    CalendarScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}

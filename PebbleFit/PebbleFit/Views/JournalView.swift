import SwiftUI

struct JournalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    @State private var journalEntries: [BehaviorCategory: [TrackedBehavior]] = [:]
    @State private var notes: String = ""
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Header
                    JournalDateHeader(selectedDate: $selectedDate)
                        .padding(.horizontal)

                    // Behavior Categories
                    ForEach(BehaviorCategory.allCases, id: \.self) { category in
                        BehaviorCategorySection(
                            category: category,
                            trackedBehaviors: $journalEntries[category, default: getDefaultBehaviors(for: category)]
                        )
                        .padding(.horizontal)
                    }

                    // Notes Section
                    NotesSection(notes: $notes)
                        .padding(.horizontal)

                    // Save Button
                    Button(action: saveJournal) {
                        Text("Save Journal Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentGreen)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Journal Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your journal entry has been saved successfully.")
            }
        }
        .onAppear {
            initializeBehaviors()
        }
    }

    private func initializeBehaviors() {
        for category in BehaviorCategory.allCases {
            journalEntries[category] = getDefaultBehaviors(for: category)
        }
    }

    private func getDefaultBehaviors(for category: BehaviorCategory) -> [TrackedBehavior] {
        switch category {
        case .recovery:
            return [
                TrackedBehavior(name: "Ice Bath / Cold Exposure", isTracked: false),
                TrackedBehavior(name: "Massage / Foam Rolling", isTracked: false),
                TrackedBehavior(name: "Stretching / Mobility", isTracked: false),
                TrackedBehavior(name: "Sauna", isTracked: false),
                TrackedBehavior(name: "Compression Therapy", isTracked: false)
            ]
        case .sleep:
            return [
                TrackedBehavior(name: "Blue Light Blocking", isTracked: false),
                TrackedBehavior(name: "Sleep Mask", isTracked: false),
                TrackedBehavior(name: "White Noise / Sound Machine", isTracked: false),
                TrackedBehavior(name: "Bed Partner", isTracked: false),
                TrackedBehavior(name: "Room Temperature Controlled", isTracked: false)
            ]
        case .nutrition:
            return [
                TrackedBehavior(name: "Ate Clean", isTracked: false),
                TrackedBehavior(name: "Adequate Hydration", isTracked: false),
                TrackedBehavior(name: "Protein Intake Met", isTracked: false),
                TrackedBehavior(name: "Supplements Taken", isTracked: false),
                TrackedBehavior(name: "Intermittent Fasting", isTracked: false)
            ]
        case .substances:
            return [
                TrackedBehavior(name: "Alcohol", isTracked: false, hasQuantity: true, quantity: 0),
                TrackedBehavior(name: "Caffeine", isTracked: false, hasQuantity: true, quantity: 0),
                TrackedBehavior(name: "Cannabis", isTracked: false),
                TrackedBehavior(name: "Nicotine", isTracked: false)
            ]
        case .mentalHealth:
            return [
                TrackedBehavior(name: "Meditation", isTracked: false, hasDuration: true, duration: 0),
                TrackedBehavior(name: "Journaling", isTracked: false),
                TrackedBehavior(name: "Therapy Session", isTracked: false),
                TrackedBehavior(name: "High Stress Day", isTracked: false),
                TrackedBehavior(name: "Mindfulness Practice", isTracked: false)
            ]
        case .medication:
            return [
                TrackedBehavior(name: "Prescription Medication", isTracked: false),
                TrackedBehavior(name: "Sleep Aid", isTracked: false),
                TrackedBehavior(name: "Pain Medication", isTracked: false)
            ]
        case .lifestyle:
            return [
                TrackedBehavior(name: "Worked From Home", isTracked: false),
                TrackedBehavior(name: "Travel Day", isTracked: false),
                TrackedBehavior(name: "Vacation / Rest Day", isTracked: false),
                TrackedBehavior(name: "Outdoor Time", isTracked: false),
                TrackedBehavior(name: "Social Activity", isTracked: false)
            ]
        }
    }

    private func saveJournal() {
        // Save journal entry to persistent storage
        showingSaveConfirmation = true
    }
}

// MARK: - Tracked Behavior Model
struct TrackedBehavior: Identifiable {
    let id = UUID()
    var name: String
    var isTracked: Bool
    var hasQuantity: Bool = false
    var quantity: Int = 0
    var hasDuration: Bool = false
    var duration: Int = 0 // minutes
    var hasTime: Bool = false
    var time: Date = Date()
}

// MARK: - Journal Date Header
struct JournalDateHeader: View {
    @Binding var selectedDate: Date

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }

    var body: some View {
        HStack {
            Button(action: previousDay) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                    .foregroundColor(.white)

                if Calendar.current.isDateInToday(selectedDate) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.accentGreen)
                }
            }

            Spacer()

            Button(action: nextDay) {
                Image(systemName: "chevron.right")
                    .foregroundColor(canGoNext ? .white : .gray)
            }
            .disabled(!canGoNext)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    private var canGoNext: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }

    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    private func nextDay() {
        guard canGoNext else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}

// MARK: - Behavior Category Section
struct BehaviorCategorySection: View {
    let category: BehaviorCategory
    @Binding var trackedBehaviors: [TrackedBehavior]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                        .frame(width: 24)

                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Count of tracked items
                    let trackedCount = trackedBehaviors.filter { $0.isTracked }.count
                    if trackedCount > 0 {
                        Text("\(trackedCount)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(category.color)
                            .cornerRadius(10)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }

            if isExpanded {
                ForEach($trackedBehaviors) { $behavior in
                    BehaviorToggleRow(behavior: $behavior, categoryColor: category.color)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct BehaviorToggleRow: View {
    @Binding var behavior: TrackedBehavior
    let categoryColor: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: { behavior.isTracked.toggle() }) {
                    Image(systemName: behavior.isTracked ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(behavior.isTracked ? categoryColor : .gray)
                        .font(.title3)
                }

                Text(behavior.name)
                    .font(.subheadline)
                    .foregroundColor(behavior.isTracked ? .white : .gray)

                Spacer()
            }

            // Additional inputs when tracked
            if behavior.isTracked {
                if behavior.hasQuantity {
                    HStack {
                        Text("How many?")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        HStack(spacing: 15) {
                            Button(action: { if behavior.quantity > 0 { behavior.quantity -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.gray)
                            }

                            Text("\(behavior.quantity)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 30)

                            Button(action: { behavior.quantity += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(categoryColor)
                            }
                        }
                    }
                    .padding(.leading, 30)
                }

                if behavior.hasDuration {
                    HStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        HStack(spacing: 15) {
                            Button(action: { if behavior.duration >= 5 { behavior.duration -= 5 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.gray)
                            }

                            Text("\(behavior.duration) min")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 60)

                            Button(action: { behavior.duration += 5 }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(categoryColor)
                            }
                        }
                    }
                    .padding(.leading, 30)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Notes Section
struct NotesSection: View {
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.accentYellow)
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(10)
                .background(Color.cardBackgroundLight)
                .cornerRadius(10)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)

            Text("Add any additional notes about your day, how you felt, or anything that might affect your recovery.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Journal History View
struct JournalHistoryView: View {
    @State private var journalEntries: [Date: JournalEntry] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(getLast30Days(), id: \.self) { date in
                        JournalHistoryRow(date: date, hasEntry: journalEntries[date] != nil)
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Journal History")
        }
    }

    private func getLast30Days() -> [Date] {
        (0..<30).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date())
        }
    }
}

struct JournalHistoryRow: View {
    let date: Date
    let hasEntry: Bool

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                if Calendar.current.isDateInToday(date) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.accentGreen)
                }
            }

            Spacer()

            if hasEntry {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentGreen)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    JournalView()
}

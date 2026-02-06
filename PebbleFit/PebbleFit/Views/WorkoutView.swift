import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isWorkoutActive = false
    @State private var selectedWorkoutType: WorkoutType = .running
    @State private var showingWorkoutTypeSelector = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var heartRateHistory: [HeartRateReading] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isWorkoutActive {
                    ActiveWorkoutView(
                        workoutType: selectedWorkoutType,
                        elapsedTime: $elapsedTime,
                        heartRateHistory: $heartRateHistory,
                        onEnd: endWorkout
                    )
                } else {
                    WorkoutStartView(
                        selectedWorkoutType: $selectedWorkoutType,
                        showingWorkoutTypeSelector: $showingWorkoutTypeSelector,
                        onStart: startWorkout
                    )
                }
            }
            .navigationTitle(isWorkoutActive ? "Active Workout" : "Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingWorkoutTypeSelector) {
                WorkoutTypeSelectorView(selectedType: $selectedWorkoutType)
            }
        }
    }

    private func startWorkout() {
        isWorkoutActive = true
        elapsedTime = 0
        heartRateHistory = []

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1

            // Simulate heart rate reading
            if Int(elapsedTime) % 5 == 0 {
                let simulatedHR = Double.random(in: 120...170)
                let reading = HeartRateReading(timestamp: Date(), bpm: simulatedHR)
                heartRateHistory.append(reading)
            }
        }
    }

    private func endWorkout() {
        timer?.invalidate()
        timer = nil
        isWorkoutActive = false

        // Save workout
        let avgHR = heartRateHistory.isEmpty ? 0 : heartRateHistory.map { $0.bpm }.reduce(0, +) / Double(heartRateHistory.count)
        let maxHR = heartRateHistory.map { $0.bpm }.max() ?? 0
        let calories = elapsedTime / 60 * 8 // Rough estimate

        let workout = Workout(
            id: UUID(),
            type: selectedWorkoutType,
            startTime: Date().addingTimeInterval(-elapsedTime),
            endTime: Date(),
            duration: elapsedTime,
            strain: StrainCalculator.shared.calculateLiveStrain(heartRateHistory: heartRateHistory, workoutType: selectedWorkoutType),
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            calories: calories,
            distance: nil,
            notes: nil
        )

        healthManager.saveWorkout(workout)
    }
}

// MARK: - Workout Start View
struct WorkoutStartView: View {
    @Binding var selectedWorkoutType: WorkoutType
    @Binding var showingWorkoutTypeSelector: Bool
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Selected Workout Type
                Button(action: { showingWorkoutTypeSelector = true }) {
                    HStack {
                        Image(systemName: selectedWorkoutType.icon)
                            .font(.title)
                            .foregroundColor(selectedWorkoutType.color)
                            .frame(width: 50, height: 50)
                            .background(selectedWorkoutType.color.opacity(0.2))
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedWorkoutType.rawValue)
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)

                            Text("Tap to change activity")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                }
                .padding(.horizontal)

                // Quick Start Buttons
                VStack(alignment: .leading, spacing: 15) {
                    Text("Quick Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(WorkoutType.popular, id: \.self) { type in
                            QuickStartButton(type: type) {
                                selectedWorkoutType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Start Button
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start \(selectedWorkoutType.rawValue)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentGreen)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Recent Workouts
                RecentWorkoutsSection()
                    .padding(.horizontal)

                // Strain Coach Suggestion
                StrainCoachSuggestionCard()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct QuickStartButton: View {
    let type: WorkoutType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(type.color)

                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    let workoutType: WorkoutType
    @Binding var elapsedTime: TimeInterval
    @Binding var heartRateHistory: [HeartRateReading]
    let onEnd: () -> Void

    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingEndConfirmation = false

    private var currentHeartRate: Double {
        heartRateHistory.last?.bpm ?? bluetoothManager.currentHeartRate
    }

    private var currentStrain: Double {
        StrainCalculator.shared.calculateLiveStrain(heartRateHistory: heartRateHistory, workoutType: workoutType)
    }

    private var averageHeartRate: Double {
        guard !heartRateHistory.isEmpty else { return 0 }
        return heartRateHistory.map { $0.bpm }.reduce(0, +) / Double(heartRateHistory.count)
    }

    private var currentZone: Int {
        StrainCalculator.shared.getZone(for: currentHeartRate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Workout Type Header
                HStack {
                    Image(systemName: workoutType.icon)
                        .font(.title)
                        .foregroundColor(workoutType.color)

                    Text(workoutType.rawValue)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)

                    Spacer()

                    // Live indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)

                // Main Stats
                VStack(spacing: 20) {
                    // Timer
                    VStack(spacing: 4) {
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 60, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Heart Rate and Strain
                    HStack(spacing: 30) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.cardBackgroundLight, lineWidth: 8)
                                    .frame(width: 100, height: 100)

                                Circle()
                                    .trim(from: 0, to: min(currentHeartRate / 200, 1))
                                    .stroke(
                                        zoneColor(currentZone),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 2) {
                                    Text("\(Int(currentHeartRate))")
                                        .font(.title.bold())
                                        .foregroundColor(.white)

                                    Text("BPM")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }

                            Text("Zone \(currentZone)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(zoneColor(currentZone))
                        }

                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.cardBackgroundLight, lineWidth: 8)
                                    .frame(width: 100, height: 100)

                                Circle()
                                    .trim(from: 0, to: currentStrain / 21)
                                    .stroke(
                                        Color.accentOrange,
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 2) {
                                    Text(String(format: "%.1f", currentStrain))
                                        .font(.title.bold())
                                        .foregroundColor(.white)

                                    Text("Strain")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }

                            Text(strainCategory(currentStrain))
                                .font(.caption.weight(.medium))
                                .foregroundColor(.accentOrange)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)

                // Heart Rate Graph
                VStack(alignment: .leading, spacing: 15) {
                    Text("Heart Rate")
                        .font(.headline)
                        .foregroundColor(.white)

                    if heartRateHistory.count > 1 {
                        HeartRateGraphView(readings: heartRateHistory)
                            .frame(height: 100)
                    } else {
                        Text("Heart rate data will appear as you exercise")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(height: 100)
                    }

                    // Stats row
                    HStack {
                        StatMiniBox(label: "Avg", value: "\(Int(averageHeartRate))", unit: "BPM")
                        StatMiniBox(label: "Max", value: "\(Int(heartRateHistory.map { $0.bpm }.max() ?? 0))", unit: "BPM")
                        StatMiniBox(label: "Calories", value: "\(Int(elapsedTime / 60 * 8))", unit: "kcal")
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)

                // Heart Rate Zones
                HeartRateZonesCard(heartRateHistory: heartRateHistory)
                    .padding(.horizontal)

                // End Workout Button
                Button(action: { showingEndConfirmation = true }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Workout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentRed)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.vertical)
        }
        .alert("End Workout?", isPresented: $showingEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End", role: .destructive, action: onEnd)
        } message: {
            Text("Are you sure you want to end this workout?")
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return .blue
        case 2: return .accentGreen
        case 3: return .accentYellow
        case 4: return .accentOrange
        case 5: return .accentRed
        default: return .gray
        }
    }

    private func strainCategory(_ strain: Double) -> String {
        if strain < 9 { return "Light" }
        if strain < 14 { return "Moderate" }
        if strain < 18 { return "High" }
        return "All Out"
    }
}

// MARK: - Heart Rate Graph View
struct HeartRateGraphView: View {
    let readings: [HeartRateReading]

    var body: some View {
        GeometryReader { geometry in
            let maxHR = readings.map { $0.bpm }.max() ?? 200
            let minHR = readings.map { $0.bpm }.min() ?? 60
            let range = max(maxHR - minHR, 1)

            Path { path in
                guard readings.count > 1 else { return }

                let stepX = geometry.size.width / CGFloat(readings.count - 1)

                for (index, reading) in readings.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = (reading.bpm - minHR) / range
                    let y = geometry.size.height * (1 - CGFloat(normalizedY))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.accentRed, .accentOrange],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
    }
}

// MARK: - Stat Mini Box
struct StatMiniBox: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.cardBackgroundLight)
        .cornerRadius(8)
    }
}

// MARK: - Heart Rate Zones Card
struct HeartRateZonesCard: View {
    let heartRateHistory: [HeartRateReading]

    private func timeInZone(_ zone: Int) -> TimeInterval {
        // Calculate time spent in each zone
        let zoneReadings = heartRateHistory.filter {
            StrainCalculator.shared.getZone(for: $0.bpm) == zone
        }
        return TimeInterval(zoneReadings.count * 5) // 5 seconds per reading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Time in Zones")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ZoneRow(zone: 5, name: "Peak", time: timeInZone(5), color: .accentRed)
                ZoneRow(zone: 4, name: "Hard", time: timeInZone(4), color: .accentOrange)
                ZoneRow(zone: 3, name: "Cardio", time: timeInZone(3), color: .accentYellow)
                ZoneRow(zone: 2, name: "Fat Burn", time: timeInZone(2), color: .accentGreen)
                ZoneRow(zone: 1, name: "Recovery", time: timeInZone(1), color: .accentBlue)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct ZoneRow: View {
    let zone: Int
    let name: String
    let time: TimeInterval
    let color: Color

    private var totalTime: TimeInterval {
        max(time, 1)
    }

    var body: some View {
        HStack {
            Text("Zone \(zone)")
                .font(.caption.weight(.medium))
                .foregroundColor(color)
                .frame(width: 50, alignment: .leading)

            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geometry.size.width * min(time / 600, 1)) // Max 10 minutes
            }
            .frame(height: 8)

            Text(formatTime(time))
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 50, alignment: .trailing)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Recent Workouts Section
struct RecentWorkoutsSection: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                NavigationLink(destination: WorkoutHistoryView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentGreen)
                }
            }

            if healthManager.recentWorkouts.isEmpty {
                Text("No recent workouts")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                ForEach(healthManager.recentWorkouts.prefix(3)) { workout in
                    RecentWorkoutRow(workout: workout)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct RecentWorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack {
            Image(systemName: workout.type.icon)
                .foregroundColor(workout.type.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                Text(formatDate(workout.startTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", workout.strain))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.accentOrange)

                Text(formatDuration(workout.duration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

// MARK: - Strain Coach Suggestion Card
struct StrainCoachSuggestionCard: View {
    @EnvironmentObject var healthManager: HealthManager

    private var recovery: Double {
        healthManager.todayRecovery?.score ?? 50
    }

    private var suggestion: String {
        if recovery >= 67 {
            return "Your recovery is excellent! Consider a high-intensity workout today."
        } else if recovery >= 34 {
            return "Moderate activity recommended. A medium-intensity workout would be ideal."
        } else {
            return "Focus on recovery today. Light activity or rest is recommended."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentGreen)

                Text("Strain Coach")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(suggestion)
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                Text("Today's Target:")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(getTargetStrain())
                    .font(.caption.weight(.medium))
                    .foregroundColor(.accentOrange)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func getTargetStrain() -> String {
        if recovery >= 67 {
            return "14.0 - 21.0"
        } else if recovery >= 34 {
            return "10.0 - 14.0"
        } else {
            return "0.0 - 10.0"
        }
    }
}

// MARK: - Workout Type Selector View
struct WorkoutTypeSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedType: WorkoutType

    let sections: [(title: String, types: [WorkoutType])] = [
        ("Cardio", [.running, .cycling, .swimming, .rowing, .elliptical, .stairClimber]),
        ("Strength", [.weightTraining, .crossfit, .hiit]),
        ("Sports", [.basketball, .soccer, .tennis, .golf]),
        ("Mind & Body", [.yoga, .pilates, .dance]),
        ("Other", [.hiking, .walking, .boxing, .other])
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.title) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.types, id: \.self) { type in
                            Button(action: {
                                selectedType = type
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: type.icon)
                                        .foregroundColor(type.color)
                                        .frame(width: 30)

                                    Text(type.rawValue)
                                        .foregroundColor(.white)

                                    Spacer()

                                    if type == selectedType {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentGreen)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        List {
            ForEach(healthManager.recentWorkouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    RecentWorkoutRow(workout: workout)
                }
            }
        }
        .navigationTitle("Workout History")
    }
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: workout.type.icon)
                        .font(.system(size: 50))
                        .foregroundColor(workout.type.color)

                    Text(workout.type.rawValue)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text(formatDate(workout.startTime))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground)
                .cornerRadius(16)

                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    WorkoutStatCard(title: "Duration", value: formatDuration(workout.duration), icon: "clock.fill", color: .accentBlue)
                    WorkoutStatCard(title: "Strain", value: String(format: "%.1f", workout.strain), icon: "flame.fill", color: .accentOrange)
                    WorkoutStatCard(title: "Avg HR", value: "\(Int(workout.averageHeartRate)) BPM", icon: "heart.fill", color: .red)
                    WorkoutStatCard(title: "Max HR", value: "\(Int(workout.maxHeartRate)) BPM", icon: "heart.fill", color: .accentRed)
                    WorkoutStatCard(title: "Calories", value: "\(Int(workout.calories)) kcal", icon: "flame.fill", color: .accentYellow)
                    if let distance = workout.distance {
                        WorkoutStatCard(title: "Distance", value: String(format: "%.2f km", distance / 1000), icon: "figure.run", color: .accentGreen)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

struct WorkoutStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    WorkoutView()
        .environmentObject(HealthManager.shared)
        .environmentObject(BluetoothManager.shared)
}

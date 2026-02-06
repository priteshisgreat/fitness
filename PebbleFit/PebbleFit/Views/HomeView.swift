import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingWorkoutPicker = false
    @State private var selectedTimeRange: TimeRange = .today

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status Banner
                    if !bluetoothManager.isConnected {
                        ConnectionBanner()
                    }

                    // Main Metrics Dials
                    HStack(spacing: 15) {
                        RecoveryDial(recovery: healthManager.todayRecovery)
                        StrainDial(strain: healthManager.todayStrain)
                        SleepDial(sleep: healthManager.lastNightSleep)
                    }
                    .padding(.horizontal)

                    // Health Monitor Card
                    HealthMonitorCard()
                        .padding(.horizontal)

                    // Quick Actions
                    QuickActionsRow(showingWorkoutPicker: $showingWorkoutPicker)
                        .padding(.horizontal)

                    // Today's Activity Timeline
                    ActivityTimelineCard()
                        .padding(.horizontal)

                    // Weekly Trends Preview
                    WeeklyTrendsCard()
                        .padding(.horizontal)

                    // Journal Prompt
                    JournalPromptCard()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        if bluetoothManager.isConnected {
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                                .foregroundColor(.accentGreen)
                        }
                        if let battery = bluetoothManager.batteryLevel {
                            BatteryIndicator(level: battery)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingWorkoutPicker) {
            WorkoutPickerView()
        }
        .onAppear {
            healthManager.fetchAllHealthData()
        }
    }
}

// MARK: - Connection Banner
struct ConnectionBanner: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .foregroundColor(.accentYellow)

            Text("Pebble Qore 2 not connected")
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Button("Connect") {
                bluetoothManager.startScanning()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.accentGreen)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Metric Dials
struct RecoveryDial: View {
    let recovery: RecoveryScore?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.cardBackgroundLight, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: (recovery?.score ?? 0) / 100)
                    .stroke(
                        recovery?.category.color ?? .gray,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: recovery?.score)

                VStack(spacing: 2) {
                    Text("\(Int(recovery?.score ?? 0))%")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Recovery")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 100, height: 100)

            Text(recovery?.category.rawValue ?? "—")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(recovery?.category.color ?? .gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct StrainDial: View {
    let strain: StrainScore?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.cardBackgroundLight, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: (strain?.score ?? 0) / 21)
                    .stroke(
                        strain?.category.color ?? .gray,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: strain?.score)

                VStack(spacing: 2) {
                    Text(String(format: "%.1f", strain?.score ?? 0))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Strain")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 100, height: 100)

            Text(strain?.category.rawValue ?? "—")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(strain?.category.color ?? .gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct SleepDial: View {
    let sleep: SleepData?

    private var sleepHours: Double {
        (sleep?.sleepDuration ?? 0) / 3600
    }

    private var performanceColor: Color {
        guard let perf = sleep?.performance else { return .gray }
        if perf >= 85 { return .accentGreen }
        if perf >= 70 { return .accentYellow }
        return .accentRed
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.cardBackgroundLight, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: min(1, sleepHours / 8))
                    .stroke(
                        performanceColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: sleepHours)

                VStack(spacing: 2) {
                    Text(String(format: "%.1f", sleepHours))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Hours")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 100, height: 100)

            Text("\(Int(sleep?.performance ?? 0))% Sleep")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(performanceColor)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Health Monitor Card
struct HealthMonitorCard: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Health Monitor")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                NavigationLink(destination: HealthMonitorDetailView()) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing: 20) {
                MetricItem(
                    icon: "heart.fill",
                    color: .red,
                    value: "\(Int(bluetoothManager.isConnected ? bluetoothManager.currentHeartRate : healthManager.currentHeartRate))",
                    unit: "BPM",
                    label: "Heart Rate"
                )

                MetricItem(
                    icon: "waveform.path.ecg",
                    color: .accentGreen,
                    value: "\(Int(healthManager.latestHRV))",
                    unit: "ms",
                    label: "HRV"
                )

                MetricItem(
                    icon: "heart.text.square",
                    color: .pink,
                    value: "\(Int(healthManager.restingHeartRate))",
                    unit: "BPM",
                    label: "Resting HR"
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct MetricItem: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Actions
struct QuickActionsRow: View {
    @Binding var showingWorkoutPicker: Bool

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus.circle.fill",
                title: "Start Workout",
                color: .accentGreen
            ) {
                showingWorkoutPicker = true
            }

            NavigationLink(destination: JournalView()) {
                QuickActionButtonContent(
                    icon: "book.fill",
                    title: "Journal",
                    color: .accentPurple
                )
            }

            NavigationLink(destination: TrendsView()) {
                QuickActionButtonContent(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trends",
                    color: .accentBlue
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionButtonContent(icon: icon, title: title, color: color)
        }
    }
}

struct QuickActionButtonContent: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Activity Timeline Card
struct ActivityTimelineCard: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Today's Activity")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(healthManager.todaySteps) steps")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let workouts = healthManager.todayStrain?.workouts, !workouts.isEmpty {
                ForEach(workouts) { workout in
                    WorkoutTimelineItem(workout: workout)
                }
            } else {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.accentBlue)

                    VStack(alignment: .leading) {
                        Text("No workouts logged today")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("Tap + to start a workout")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // Steps and Calories Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(healthManager.todaySteps)")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Text("Steps")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(healthManager.todayCalories))")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct WorkoutTimelineItem: View {
    let workout: Workout

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack {
            Image(systemName: workout.type.icon)
                .foregroundColor(workout.type.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.type.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                Text(timeFormatter.string(from: workout.startTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", workout.strain))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.accentOrange)

                Text(formatDuration(workout.duration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Weekly Trends Card
struct WeeklyTrendsCard: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                NavigationLink(destination: TrendsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentGreen)
                }
            }

            // Mini recovery chart
            HStack(spacing: 4) {
                ForEach(healthManager.weeklyRecoveries.prefix(7)) { recovery in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(recovery.category.color)
                            .frame(width: 30, height: CGFloat(recovery.score) * 0.6)

                        Text(getDayLabel(recovery.date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .frame(height: 80)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func getDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

// MARK: - Journal Prompt Card
struct JournalPromptCard: View {
    @State private var showingJournal = false

    var body: some View {
        Button(action: { showingJournal = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log your day")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Track behaviors that affect your recovery")
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
        .sheet(isPresented: $showingJournal) {
            JournalView()
        }
    }
}

// MARK: - Battery Indicator
struct BatteryIndicator: View {
    let level: Int

    private var color: Color {
        if level > 50 { return .accentGreen }
        if level > 20 { return .accentYellow }
        return .accentRed
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: batteryIcon)
                .foregroundColor(color)
            Text("\(level)%")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private var batteryIcon: String {
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }
}

// MARK: - Time Range Selector
enum TimeRange: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

// MARK: - Placeholder Views
struct NotificationsView: View {
    var body: some View {
        Text("Notifications")
            .navigationTitle("Notifications")
    }
}

struct HealthMonitorDetailView: View {
    var body: some View {
        Text("Health Monitor Details")
            .navigationTitle("Health Monitor")
    }
}

struct WorkoutPickerView: View {
    @Environment(\.dismiss) var dismiss

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        NavigationLink(destination: ActiveWorkoutView(workoutType: type)) {
                            VStack(spacing: 10) {
                                Image(systemName: type.icon)
                                    .font(.title)
                                    .foregroundColor(type.color)

                                Text(type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ActiveWorkoutView: View {
    let workoutType: WorkoutType
    @Environment(\.dismiss) var dismiss
    @State private var isActive = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var currentStrain: Double = 0
    @State private var heartRate: Double = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 30) {
            // Workout Type Header
            VStack(spacing: 10) {
                Image(systemName: workoutType.icon)
                    .font(.system(size: 60))
                    .foregroundColor(workoutType.color)

                Text(workoutType.rawValue)
                    .font(.title)
                    .foregroundColor(.white)
            }

            // Timer
            Text(formatTime(elapsedTime))
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            // Live Metrics
            HStack(spacing: 40) {
                VStack {
                    Text("\(Int(heartRate))")
                        .font(.title.bold())
                        .foregroundColor(.red)
                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                VStack {
                    Text(String(format: "%.1f", currentStrain))
                        .font(.title.bold())
                        .foregroundColor(.accentOrange)
                    Text("Strain")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Control Buttons
            HStack(spacing: 40) {
                if isActive {
                    Button(action: pauseWorkout) {
                        Image(systemName: "pause.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.accentYellow)
                            .clipShape(Circle())
                    }

                    Button(action: stopWorkout) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.accentRed)
                            .clipShape(Circle())
                    }
                } else {
                    Button(action: startWorkout) {
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.accentGreen)
                            .clipShape(Circle())
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.appBackground)
        .navigationBarBackButtonHidden(isActive)
    }

    private func startWorkout() {
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            // Simulate heart rate and strain updates
            heartRate = Double.random(in: 120...160)
            currentStrain = min(21, elapsedTime / 600 * 5) // Gradual strain increase
        }
    }

    private func pauseWorkout() {
        isActive = false
        timer?.invalidate()
    }

    private func stopWorkout() {
        timer?.invalidate()
        dismiss()
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
}

#Preview {
    HomeView()
        .environmentObject(HealthManager.shared)
        .environmentObject(BluetoothManager.shared)
        .environmentObject(AppState.shared)
}

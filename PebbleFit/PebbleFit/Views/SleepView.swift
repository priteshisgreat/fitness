import SwiftUI

struct SleepView: View {
    @EnvironmentObject var healthManager: HealthManager
    @State private var selectedDate = Date()
    @State private var showingSleepCoach = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selector
                    DateSelectorBar(selectedDate: $selectedDate)
                        .padding(.horizontal)

                    // Sleep Performance Card
                    if let sleep = healthManager.lastNightSleep {
                        SleepPerformanceCard(sleep: sleep)
                            .padding(.horizontal)

                        // Sleep Stages Chart
                        SleepStagesCard(sleep: sleep)
                            .padding(.horizontal)

                        // Sleep Metrics Grid
                        SleepMetricsGrid(sleep: sleep)
                            .padding(.horizontal)

                        // Sleep Quality Breakdown
                        SleepQualityCard(sleep: sleep)
                            .padding(.horizontal)
                    } else {
                        NoSleepDataCard()
                            .padding(.horizontal)
                    }

                    // Sleep Coach Card
                    SleepCoachCard(showingSleepCoach: $showingSleepCoach)
                        .padding(.horizontal)

                    // Sleep Trends
                    SleepTrendsCard()
                        .padding(.horizontal)

                    // Sleep Tips
                    SleepTipsCard()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Sleep")
            .sheet(isPresented: $showingSleepCoach) {
                SleepCoachView()
            }
        }
    }
}

// MARK: - Date Selector
struct DateSelectorBar: View {
    @Binding var selectedDate: Date

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }

    var body: some View {
        HStack {
            Button(action: previousDay) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
            }

            Spacer()

            Text(dateFormatter.string(from: selectedDate))
                .font(.headline)
                .foregroundColor(.white)

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
        Calendar.current.isDateInToday(selectedDate) == false
    }

    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    private func nextDay() {
        guard canGoNext else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}

// MARK: - Sleep Performance Card
struct SleepPerformanceCard: View {
    let sleep: SleepData

    private var performanceColor: Color {
        if sleep.performance >= 85 { return .accentGreen }
        if sleep.performance >= 70 { return .accentYellow }
        return .accentRed
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(spacing: 20) {
            // Main Performance Ring
            ZStack {
                Circle()
                    .stroke(Color.cardBackgroundLight, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: sleep.performance / 100)
                    .stroke(
                        performanceColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(sleep.performance))%")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)

                    Text("Sleep Performance")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 160, height: 160)

            // Sleep Times
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.accentPurple)
                    Text(timeFormatter.string(from: sleep.bedTime))
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Bedtime")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Rectangle()
                    .fill(Color.cardBackgroundLight)
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text(formatDuration(sleep.sleepDuration))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("of \(formatDuration(sleep.sleepNeed)) needed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Rectangle()
                    .fill(Color.cardBackgroundLight)
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Image(systemName: "sunrise.fill")
                        .foregroundColor(.accentYellow)
                    Text(timeFormatter.string(from: sleep.wakeTime))
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Wake")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Sleep Stages Card
struct SleepStagesCard: View {
    let sleep: SleepData

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sleep Stages")
                .font(.headline)
                .foregroundColor(.white)

            // Stages Timeline
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(sleep.stages) { stage in
                        Rectangle()
                            .fill(stage.stage.color)
                            .frame(width: CGFloat(stage.duration / sleep.totalDuration) * geometry.size.width)
                    }
                }
                .cornerRadius(4)
            }
            .frame(height: 30)

            // Stage Legend
            HStack(spacing: 20) {
                StageLegendItem(stage: .awake, duration: sleep.awakeTime)
                StageLegendItem(stage: .light, duration: sleep.lightSleep)
                StageLegendItem(stage: .deep, duration: sleep.deepSleep)
                StageLegendItem(stage: .rem, duration: sleep.remSleep)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct StageLegendItem: View {
    let stage: SleepStageType
    let duration: TimeInterval

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(stage.color)
                    .frame(width: 8, height: 8)
                Text(stage.rawValue)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Text(formatDuration(duration))
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Sleep Metrics Grid
struct SleepMetricsGrid: View {
    let sleep: SleepData

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            SleepMetricCard(
                icon: "gauge.with.dots.needle.33percent",
                title: "Efficiency",
                value: "\(Int(sleep.efficiency))%",
                subtitle: "Time asleep vs in bed",
                color: sleep.efficiency >= 85 ? .accentGreen : .accentYellow
            )

            SleepMetricCard(
                icon: "clock.arrow.circlepath",
                title: "Consistency",
                value: "\(Int(sleep.consistency))%",
                subtitle: "Sleep schedule regularity",
                color: sleep.consistency >= 80 ? .accentGreen : .accentYellow
            )

            SleepMetricCard(
                icon: "hourglass",
                title: "Sleep Latency",
                value: formatMinutes(sleep.latency),
                subtitle: "Time to fall asleep",
                color: sleep.latency < 20 * 60 ? .accentGreen : .accentYellow
            )

            SleepMetricCard(
                icon: "exclamationmark.triangle",
                title: "Disturbances",
                value: "\(sleep.disturbances)",
                subtitle: "Wake events",
                color: sleep.disturbances <= 3 ? .accentGreen : .accentRed
            )
        }
    }

    private func formatMinutes(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) min"
    }
}

struct SleepMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Sleep Quality Card
struct SleepQualityCard: View {
    let sleep: SleepData

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sleep Quality Analysis")
                .font(.headline)
                .foregroundColor(.white)

            // Deep Sleep
            QualityBar(
                label: "Deep Sleep",
                value: sleep.deepSleep,
                target: sleep.sleepDuration * 0.20, // Target 20%
                color: .sleepDeep
            )

            // REM Sleep
            QualityBar(
                label: "REM Sleep",
                value: sleep.remSleep,
                target: sleep.sleepDuration * 0.25, // Target 25%
                color: .sleepREM
            )

            // Sleep Debt
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sleep Debt")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatHours(sleep.sleepDebt))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(sleep.sleepDebt > 2 * 3600 ? .accentRed : .accentGreen)
                }

                Text("Accumulated sleep deficit that affects recovery")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = seconds / 3600
        return String(format: "%.1fh", hours)
    }
}

struct QualityBar: View {
    let label: String
    let value: TimeInterval
    let target: TimeInterval
    let color: Color

    private var percentage: Double {
        min(1, value / target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text(formatDuration(value))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cardBackgroundLight)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - No Sleep Data Card
struct NoSleepDataCard: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Sleep Data")
                .font(.title2.weight(.medium))
                .foregroundColor(.white)

            Text("Sleep data will appear after you've worn your Pebble Qore 2 during sleep")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Sleep Coach Card
struct SleepCoachCard: View {
    @Binding var showingSleepCoach: Bool

    var body: some View {
        Button(action: { showingSleepCoach = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.accentPurple)
                        Text("Sleep Coach")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text("Get personalized bedtime recommendations based on your recovery goals")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
        }
    }
}

// MARK: - Sleep Trends Card
struct SleepTrendsCard: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Weekly Sleep Trend")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                NavigationLink(destination: TrendsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentGreen)
                }
            }

            // Mini bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(healthManager.weeklySleepData.prefix(7)) { sleep in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(performanceColor(sleep.performance))
                            .frame(width: 30, height: CGFloat(sleep.sleepDuration / 3600 * 10))

                        Text(getDayLabel(sleep.date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func performanceColor(_ performance: Double) -> Color {
        if performance >= 85 { return .accentGreen }
        if performance >= 70 { return .accentYellow }
        return .accentRed
    }

    private func getDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

// MARK: - Sleep Tips Card
struct SleepTipsCard: View {
    let tips = [
        ("moon.fill", "Keep a consistent sleep schedule"),
        ("iphone.slash", "Avoid screens 1 hour before bed"),
        ("thermometer.snowflake", "Keep your room cool (65-68°F)"),
        ("cup.and.saucer", "Limit caffeine after 2 PM")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sleep Tips")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(tips, id: \.0) { icon, tip in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(.accentPurple)
                        .frame(width: 24)

                    Text(tip)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Sleep Coach View
struct SleepCoachView: View {
    @Environment(\.dismiss) var dismiss
    @State private var wakeTime = Date()
    @State private var performanceGoal: PerformanceGoal = .peak

    enum PerformanceGoal: String, CaseIterable {
        case peak = "Peak (100%)"
        case perform = "Perform (85%)"
        case getBy = "Get By (70%)"

        var sleepNeedMultiplier: Double {
            switch self {
            case .peak: return 1.0
            case .perform: return 0.85
            case .getBy: return 0.70
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Goal Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Performance Goal")
                            .font(.headline)
                            .foregroundColor(.white)

                        Picker("Goal", selection: $performanceGoal) {
                            ForEach(PerformanceGoal.allCases, id: \.self) { goal in
                                Text(goal.rawValue).tag(goal)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)

                    // Wake Time Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("When do you need to wake up?")
                            .font(.headline)
                            .foregroundColor(.white)

                        DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)

                    // Recommendation
                    RecommendedBedtimeCard(
                        wakeTime: wakeTime,
                        performanceGoal: performanceGoal
                    )
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Sleep Coach")
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

struct RecommendedBedtimeCard: View {
    let wakeTime: Date
    let performanceGoal: SleepCoachView.PerformanceGoal

    private var sleepNeed: TimeInterval {
        8 * 3600 * performanceGoal.sleepNeedMultiplier
    }

    private var recommendedBedtime: Date {
        wakeTime.addingTimeInterval(-sleepNeed - 15 * 60) // Add 15 min for falling asleep
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 50))
                .foregroundColor(.accentPurple)

            Text("Recommended Bedtime")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text(timeFormatter.string(from: recommendedBedtime))
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)

            Text("to get \(formatDuration(sleepNeed)) of sleep")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: setAlarm) {
                HStack {
                    Image(systemName: "alarm.fill")
                    Text("Set Haptic Alarm")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.accentPurple)
                .cornerRadius(25)
            }
            .padding(.top)
        }
        .padding(30)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    private func setAlarm() {
        // Would integrate with device haptic alarm
    }
}

#Preview {
    SleepView()
        .environmentObject(HealthManager.shared)
}

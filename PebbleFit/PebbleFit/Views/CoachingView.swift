import SwiftUI

struct CoachingView: View {
    @EnvironmentObject var healthManager: HealthManager
    @State private var selectedCoach: CoachType = .strain

    enum CoachType: String, CaseIterable {
        case strain = "Strain"
        case sleep = "Sleep"
        case recovery = "Recovery"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Coach Type Selector
                    Picker("Coach", selection: $selectedCoach) {
                        ForEach(CoachType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Coach Content
                    switch selectedCoach {
                    case .strain:
                        StrainCoachContent()
                    case .sleep:
                        SleepCoachContent()
                    case .recovery:
                        RecoveryCoachContent()
                    }

                    // Weekly Plan Card
                    WeeklyPlanCard()
                        .padding(.horizontal)

                    // Insights Card
                    InsightsCard()
                        .padding(.horizontal)

                    // Behavior Impact Analysis
                    BehaviorImpactCard()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Coaching")
        }
    }
}

// MARK: - Strain Coach Content
struct StrainCoachContent: View {
    @EnvironmentObject var healthManager: HealthManager

    private var recovery: RecoveryScore {
        healthManager.todayRecovery ?? RecoveryScore(
            date: Date(), score: 50, hrv: 50, restingHeartRate: 60,
            respiratoryRate: 14, sleepPerformance: 70
        )
    }

    private var recommendation: RecoveryRecommendation {
        RecoveryCalculator.shared.getRecommendation(for: recovery)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Today's Recommendation
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.accentOrange)
                    Text("Strain Coach")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                // Recovery-based recommendation
                HStack {
                    // Recovery indicator
                    ZStack {
                        Circle()
                            .stroke(Color.cardBackgroundLight, lineWidth: 6)
                            .frame(width: 70, height: 70)

                        Circle()
                            .trim(from: 0, to: recovery.score / 100)
                            .stroke(recovery.category.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(Int(recovery.score))%")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Recovery")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(recommendation.title)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(recommendation.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 10)

                    Spacer()
                }

                // Target strain range
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recommended Strain Range")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack {
                        ForEach(0..<21) { index in
                            let isInRange = Double(index) >= recommendation.suggestedStrainRange.lowerBound &&
                                          Double(index) <= recommendation.suggestedStrainRange.upperBound

                            RoundedRectangle(cornerRadius: 2)
                                .fill(isInRange ? recovery.category.color : Color.cardBackgroundLight)
                                .frame(height: 30)
                        }
                    }

                    HStack {
                        Text("\(Int(recommendation.suggestedStrainRange.lowerBound))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(recommendation.suggestedStrainRange.upperBound))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // Suggested activities
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Activities")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recommendation.activities, id: \.self) { activity in
                                VStack(spacing: 8) {
                                    Image(systemName: activity.icon)
                                        .font(.title2)
                                        .foregroundColor(activity.color)

                                    Text(activity.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.cardBackgroundLight)
                                .cornerRadius(12)
                            }
                        }
                    }
                }

                // Tips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tips for Today")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ForEach(recommendation.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentGreen)
                                .font(.caption)

                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// MARK: - Sleep Coach Content
struct SleepCoachContent: View {
    @EnvironmentObject var healthManager: HealthManager
    @State private var targetWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()

    private var sleepNeed: TimeInterval {
        let baseNeed: TimeInterval = 8 * 3600
        let strain = healthManager.todayStrain?.score ?? 10
        let strainAdjustment = (strain / 21) * 3600 // Up to 1 hour more for high strain
        let debt = healthManager.lastNightSleep?.sleepDebt ?? 0
        let debtAdjustment = min(debt * 0.3, 2 * 3600) // Recover up to 30% of debt

        return baseNeed + strainAdjustment + debtAdjustment
    }

    private var recommendedBedtime: Date {
        targetWakeTime.addingTimeInterval(-sleepNeed - 15 * 60)
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.accentPurple)
                    Text("Sleep Coach")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                // Sleep Need Calculation
                VStack(spacing: 15) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tonight's Sleep Need")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text(formatDuration(sleepNeed))
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Sleep Debt")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text(formatDuration(healthManager.lastNightSleep?.sleepDebt ?? 0))
                                .font(.title3.bold())
                                .foregroundColor(.accentRed)
                        }
                    }

                    // Breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        SleepNeedRow(label: "Base Need", value: 8 * 3600)
                        SleepNeedRow(label: "Strain Adjustment", value: (healthManager.todayStrain?.score ?? 10) / 21 * 3600)
                        if (healthManager.lastNightSleep?.sleepDebt ?? 0) > 0 {
                            SleepNeedRow(label: "Debt Recovery", value: min((healthManager.lastNightSleep?.sleepDebt ?? 0) * 0.3, 2 * 3600))
                        }
                    }
                }

                Divider()
                    .background(Color.cardBackgroundLight)

                // Wake Time Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("When do you need to wake up?")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack {
                        DatePicker("", selection: $targetWakeTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .colorScheme(.dark)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Go to bed by")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(formatTime(recommendedBedtime))
                                .font(.title2.bold())
                                .foregroundColor(.accentPurple)
                        }
                    }
                }

                // Performance Goals
                VStack(alignment: .leading, spacing: 10) {
                    Text("Performance Goals")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack(spacing: 15) {
                        PerformanceGoalButton(
                            title: "Peak",
                            percentage: 100,
                            sleepTime: formatTime(recommendedBedtime),
                            isSelected: true
                        )

                        PerformanceGoalButton(
                            title: "Perform",
                            percentage: 85,
                            sleepTime: formatTime(recommendedBedtime.addingTimeInterval(sleepNeed * 0.15)),
                            isSelected: false
                        )

                        PerformanceGoalButton(
                            title: "Get By",
                            percentage: 70,
                            sleepTime: formatTime(recommendedBedtime.addingTimeInterval(sleepNeed * 0.30)),
                            isSelected: false
                        )
                    }
                }

                // Set Alarm Button
                Button(action: setHapticAlarm) {
                    HStack {
                        Image(systemName: "alarm.fill")
                        Text("Set Haptic Alarm")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentPurple)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func setHapticAlarm() {
        // Would integrate with device haptic alarm
    }
}

struct SleepNeedRow: View {
    let label: String
    let value: TimeInterval

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text("+\(formatDuration(value))")
                .font(.caption)
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

struct PerformanceGoalButton: View {
    let title: String
    let percentage: Int
    let sleepTime: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : .gray)

            Text("\(percentage)%")
                .font(.headline)
                .foregroundColor(isSelected ? .accentPurple : .gray)

            Text(sleepTime)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isSelected ? Color.accentPurple.opacity(0.2) : Color.cardBackgroundLight)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentPurple : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Recovery Coach Content
struct RecoveryCoachContent: View {
    @EnvironmentObject var healthManager: HealthManager

    private var recovery: RecoveryScore {
        healthManager.todayRecovery ?? RecoveryScore(
            date: Date(), score: 50, hrv: 50, restingHeartRate: 60,
            respiratoryRate: 14, sleepPerformance: 70
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.accentGreen)
                    Text("Recovery Coach")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                // Recovery breakdown
                VStack(spacing: 15) {
                    RecoveryFactorRow(
                        icon: "waveform.path.ecg",
                        title: "HRV",
                        value: "\(Int(recovery.hrv)) ms",
                        status: recovery.hrv > 50 ? .good : recovery.hrv > 30 ? .moderate : .poor
                    )

                    RecoveryFactorRow(
                        icon: "heart.fill",
                        title: "Resting Heart Rate",
                        value: "\(Int(recovery.restingHeartRate)) BPM",
                        status: recovery.restingHeartRate < 60 ? .good : recovery.restingHeartRate < 70 ? .moderate : .poor
                    )

                    RecoveryFactorRow(
                        icon: "lungs.fill",
                        title: "Respiratory Rate",
                        value: "\(Int(recovery.respiratoryRate)) br/min",
                        status: recovery.respiratoryRate >= 12 && recovery.respiratoryRate <= 16 ? .good : .moderate
                    )

                    RecoveryFactorRow(
                        icon: "moon.fill",
                        title: "Sleep Performance",
                        value: "\(Int(recovery.sleepPerformance))%",
                        status: recovery.sleepPerformance > 85 ? .good : recovery.sleepPerformance > 70 ? .moderate : .poor
                    )
                }

                Divider()
                    .background(Color.cardBackgroundLight)

                // Recovery tips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recovery Tips")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ForEach(getRecoveryTips(), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.accentYellow)
                                .font(.caption)

                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }

    private func getRecoveryTips() -> [String] {
        var tips: [String] = []

        if recovery.hrv < 40 {
            tips.append("Your HRV is low. Focus on stress reduction activities like meditation or deep breathing.")
        }

        if recovery.restingHeartRate > 65 {
            tips.append("Elevated resting heart rate may indicate fatigue. Prioritize quality sleep tonight.")
        }

        if recovery.sleepPerformance < 70 {
            tips.append("Aim for more sleep tonight to improve recovery. Try going to bed 30 minutes earlier.")
        }

        if tips.isEmpty {
            tips.append("Your recovery metrics look good! Maintain your current habits.")
            tips.append("Stay hydrated throughout the day.")
        }

        return tips
    }
}

struct RecoveryFactorRow: View {
    let icon: String
    let title: String
    let value: String
    let status: RecoveryStatus

    enum RecoveryStatus {
        case good, moderate, poor

        var color: Color {
            switch self {
            case .good: return .accentGreen
            case .moderate: return .accentYellow
            case .poor: return .accentRed
            }
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)

            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Weekly Plan Card
struct WeeklyPlanCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentBlue)
                Text("Weekly Plan")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            // Week overview
            HStack(spacing: 8) {
                ForEach(0..<7) { day in
                    DayPlanIndicator(
                        day: getDayName(offset: day),
                        isToday: day == 0,
                        plannedStrain: getPlannedStrain(day: day)
                    )
                }
            }

            // Current week stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Strain")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("12.4")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Workouts")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("5")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Recovery")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("72%")
                        .font(.headline)
                        .foregroundColor(.accentGreen)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func getDayName(offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }

    private func getPlannedStrain(day: Int) -> StrainCategory {
        // Would be based on actual plan
        let categories: [StrainCategory] = [.high, .light, .moderate, .high, .light, .moderate, .light]
        return categories[day % categories.count]
    }
}

struct DayPlanIndicator: View {
    let day: String
    let isToday: Bool
    let plannedStrain: StrainCategory

    var body: some View {
        VStack(spacing: 4) {
            Text(day)
                .font(.caption2)
                .foregroundColor(isToday ? .white : .gray)

            Circle()
                .fill(plannedStrain.color)
                .frame(width: isToday ? 30 : 24, height: isToday ? 30 : 24)
                .overlay(
                    Circle()
                        .stroke(isToday ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Insights Card
struct InsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.accentYellow)
                Text("Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()

                NavigationLink(destination: InsightsDetailView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentGreen)
                }
            }

            // Sample insights
            InsightRow(
                icon: "moon.fill",
                color: .accentPurple,
                title: "Better Recovery with 7+ Hours Sleep",
                description: "You recover 23% better when sleeping 7+ hours"
            )

            InsightRow(
                icon: "drop.fill",
                color: .accentBlue,
                title: "Hydration Impact",
                description: "Days with high water intake show 15% better HRV"
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Behavior Impact Card
struct BehaviorImpactCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentGreen)
                Text("Behavior Impact")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            // Positive impacts
            VStack(alignment: .leading, spacing: 10) {
                Text("Helps Recovery")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                BehaviorImpactRow(behavior: "Meditation", impact: "+12%", isPositive: true)
                BehaviorImpactRow(behavior: "No Alcohol", impact: "+8%", isPositive: true)
            }

            Divider()
                .background(Color.cardBackgroundLight)

            // Negative impacts
            VStack(alignment: .leading, spacing: 10) {
                Text("Hurts Recovery")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                BehaviorImpactRow(behavior: "Late Caffeine", impact: "-15%", isPositive: false)
                BehaviorImpactRow(behavior: "Screen Before Bed", impact: "-10%", isPositive: false)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct BehaviorImpactRow: View {
    let behavior: String
    let impact: String
    let isPositive: Bool

    var body: some View {
        HStack {
            Text(behavior)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text(impact)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isPositive ? .accentGreen : .accentRed)
        }
    }
}

// MARK: - Insights Detail View
struct InsightsDetailView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Your insights will appear here as we learn more about your patterns.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Insights")
    }
}

#Preview {
    CoachingView()
        .environmentObject(HealthManager.shared)
}

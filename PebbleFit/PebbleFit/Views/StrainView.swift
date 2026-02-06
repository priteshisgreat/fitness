import SwiftUI

struct StrainView: View {
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var selectedDate = Date()
    @State private var showingWorkoutPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selector
                    DateSelectorBar(selectedDate: $selectedDate)
                        .padding(.horizontal)

                    // Strain Score Card
                    StrainScoreCard(strain: healthManager.todayStrain)
                        .padding(.horizontal)

                    // Strain Coach Card
                    StrainCoachCard()
                        .padding(.horizontal)

                    // Heart Rate Zones Card
                    HeartRateZonesCard()
                        .padding(.horizontal)

                    // Today's Workouts
                    WorkoutsCard(showingWorkoutPicker: $showingWorkoutPicker)
                        .padding(.horizontal)

                    // Activity Breakdown
                    ActivityBreakdownCard()
                        .padding(.horizontal)

                    // Weekly Strain Trend
                    WeeklyStrainCard()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Strain")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingWorkoutPicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentGreen)
                    }
                }
            }
            .sheet(isPresented: $showingWorkoutPicker) {
                WorkoutPickerView()
            }
        }
    }
}

// MARK: - Strain Score Card
struct StrainScoreCard: View {
    let strain: StrainScore?

    var body: some View {
        VStack(spacing: 20) {
            // Main Strain Ring
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.cardBackgroundLight, lineWidth: 15)

                // Strain segments
                ForEach(0..<21) { index in
                    Circle()
                        .trim(from: CGFloat(index) / 21, to: CGFloat(index + 1) / 21 - 0.01)
                        .stroke(
                            getSegmentColor(index, currentStrain: strain?.score ?? 0),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                // Center content
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", strain?.score ?? 0))
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)

                    Text("Day Strain")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 200, height: 200)

            // Strain Category
            HStack(spacing: 10) {
                Circle()
                    .fill(strain?.category.color ?? .gray)
                    .frame(width: 12, height: 12)

                Text(strain?.category.rawValue ?? "—")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("•")
                    .foregroundColor(.gray)

                Text(strain?.category.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Load Breakdown
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", strain?.cardiovascularLoad ?? 0))
                        .font(.title2.bold())
                        .foregroundColor(.accentRed)
                    Text("Cardio Load")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 4) {
                    Text(String(format: "%.1f", strain?.muscularLoad ?? 0))
                        .font(.title2.bold())
                        .foregroundColor(.accentPurple)
                    Text("Muscular Load")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func getSegmentColor(_ index: Int, currentStrain: Double) -> Color {
        let segmentValue = Double(index + 1)
        if segmentValue <= currentStrain {
            if index < 9 { return .blue }
            if index < 13 { return .accentYellow }
            if index < 17 { return .orange }
            return .accentRed
        }
        return Color.cardBackgroundLight
    }
}

// MARK: - Strain Coach Card
struct StrainCoachCard: View {
    @EnvironmentObject var healthManager: HealthManager

    private var strainTarget: StrainTarget {
        let recovery = healthManager.todayRecovery ?? RecoveryScore(
            date: Date(), score: 50, hrv: 50, restingHeartRate: 60,
            respiratoryRate: 14, sleepPerformance: 70
        )
        return StrainCalculator.shared.getOptimalStrainTarget(
            recovery: recovery,
            weeklyStrainHistory: healthManager.weeklyStrains
        )
    }

    private var currentZone: TrainingZone {
        StrainCalculator.shared.getTrainingZone(
            currentStrain: healthManager.todayStrain?.score ?? 0,
            target: strainTarget
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentGreen)
                Text("Strain Coach")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(currentZone.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(currentZone.color)
            }

            // Target Range Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Target")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(strainTarget.minStrain)) - \(Int(strainTarget.maxStrain))")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.cardBackgroundLight)

                        // Target range
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentGreen.opacity(0.3))
                            .frame(
                                width: CGFloat((strainTarget.maxStrain - strainTarget.minStrain) / 21) * geometry.size.width
                            )
                            .offset(x: CGFloat(strainTarget.minStrain / 21) * geometry.size.width)

                        // Current position indicator
                        Circle()
                            .fill(currentZone.color)
                            .frame(width: 16, height: 16)
                            .offset(x: CGFloat((healthManager.todayStrain?.score ?? 0) / 21) * geometry.size.width - 8)
                    }
                }
                .frame(height: 12)
            }

            Text(strainTarget.description)
                .font(.caption)
                .foregroundColor(.gray)

            // Zone indicators
            HStack(spacing: 15) {
                ForEach(TrainingZone.allCases, id: \.self) { zone in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 8, height: 8)
                        Text(zone.rawValue)
                            .font(.caption2)
                            .foregroundColor(zone == currentZone ? .white : .gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Heart Rate Zones Card
struct HeartRateZonesCard: View {
    @EnvironmentObject var healthManager: HealthManager

    private var zones: [(zone: Int, name: String, range: ClosedRange<Double>)] {
        StrainCalculator.shared.getHeartRateZones()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Heart Rate Zones")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(healthManager.currentHeartRate)) BPM")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
            }

            ForEach(zones, id: \.zone) { zoneData in
                HStack {
                    Text("Zone \(zoneData.zone)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 50, alignment: .leading)

                    Text(zoneData.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardBackgroundLight)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.heartRateZoneColor(zoneData.zone))
                                .frame(width: getZoneBarWidth(zoneData, geometry: geometry))
                        }
                    }
                    .frame(height: 20)

                    Text("\(Int(zoneData.range.lowerBound))-\(Int(zoneData.range.upperBound))")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func getZoneBarWidth(_ zoneData: (zone: Int, name: String, range: ClosedRange<Double>), geometry: GeometryProxy) -> CGFloat {
        // This would show time spent in each zone - simplified for now
        let percentage = Double(6 - zoneData.zone) / 5.0 * 0.8 // Decreasing for higher zones
        return geometry.size.width * percentage
    }
}

// MARK: - Workouts Card
struct WorkoutsCard: View {
    @EnvironmentObject var healthManager: HealthManager
    @Binding var showingWorkoutPicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Today's Workouts")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showingWorkoutPicker = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentGreen)
                }
            }

            if let workouts = healthManager.todayStrain?.workouts, !workouts.isEmpty {
                ForEach(workouts) { workout in
                    WorkoutDetailRow(workout: workout)
                }
            } else {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No workouts yet")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("Start a workout to track your strain")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct WorkoutDetailRow: View {
    let workout: Workout

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack {
            // Workout icon
            ZStack {
                Circle()
                    .fill(workout.type.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: workout.type.icon)
                    .foregroundColor(workout.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                HStack(spacing: 10) {
                    Text(timeFormatter.string(from: workout.startTime))
                    Text("•")
                    Text(formatDuration(workout.duration))
                }
                .font(.caption)
                .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", workout.strain))
                    .font(.headline)
                    .foregroundColor(.accentOrange)

                Text("\(Int(workout.calories)) cal")
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

// MARK: - Activity Breakdown Card
struct ActivityBreakdownCard: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Activity Breakdown")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                ActivityStatItem(
                    icon: "figure.walk",
                    value: "\(healthManager.todaySteps)",
                    label: "Steps",
                    color: .accentBlue
                )

                ActivityStatItem(
                    icon: "flame.fill",
                    value: "\(Int(healthManager.todayCalories))",
                    label: "Calories",
                    color: .accentOrange
                )

                ActivityStatItem(
                    icon: "clock.fill",
                    value: "0", // Would calculate active minutes
                    label: "Active Min",
                    color: .accentGreen
                )
            }

            // Steps progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Steps Goal")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(healthManager.todaySteps) / 10,000")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cardBackgroundLight)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentBlue)
                            .frame(width: min(1, CGFloat(healthManager.todaySteps) / 10000) * geometry.size.width)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct ActivityStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weekly Strain Card
struct WeeklyStrainCard: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Weekly Strain")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                NavigationLink(destination: TrendsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentGreen)
                }
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(healthManager.weeklyStrains.prefix(7)) { strain in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(strain.category.color)
                            .frame(width: 30, height: CGFloat(strain.score * 4))

                        Text(getDayLabel(strain.date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .frame(height: 100)

            // Average
            HStack {
                Text("7-Day Average")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                let avg = healthManager.weeklyStrains.prefix(7).map { $0.score }.reduce(0, +) / max(1, Double(min(7, healthManager.weeklyStrains.count)))
                Text(String(format: "%.1f", avg))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
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

#Preview {
    StrainView()
        .environmentObject(HealthManager.shared)
        .environmentObject(BluetoothManager.shared)
}

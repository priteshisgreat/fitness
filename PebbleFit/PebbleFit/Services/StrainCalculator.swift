import Foundation

class StrainCalculator {
    static let shared = StrainCalculator()

    // MARK: - User Settings
    private let userDefaults = UserDefaults.standard

    var maxHeartRate: Double {
        get {
            let stored = userDefaults.double(forKey: "maxHeartRate")
            return stored > 0 ? stored : 190 // Default
        }
        set { userDefaults.set(newValue, forKey: "maxHeartRate") }
    }

    var restingHeartRate: Double {
        get {
            let stored = userDefaults.double(forKey: "restingHeartRate")
            return stored > 0 ? stored : 60 // Default
        }
        set { userDefaults.set(newValue, forKey: "restingHeartRate") }
    }

    // MARK: - Heart Rate Zones
    func getHeartRateZones() -> [(zone: Int, name: String, range: ClosedRange<Double>)] {
        let hrReserve = maxHeartRate - restingHeartRate

        return [
            (1, "Recovery", restingHeartRate...(restingHeartRate + hrReserve * 0.5)),
            (2, "Fat Burn", (restingHeartRate + hrReserve * 0.5)...(restingHeartRate + hrReserve * 0.6)),
            (3, "Cardio", (restingHeartRate + hrReserve * 0.6)...(restingHeartRate + hrReserve * 0.7)),
            (4, "Hard", (restingHeartRate + hrReserve * 0.7)...(restingHeartRate + hrReserve * 0.85)),
            (5, "Peak", (restingHeartRate + hrReserve * 0.85)...maxHeartRate)
        ]
    }

    func getZone(for heartRate: Double) -> Int {
        let zones = getHeartRateZones()
        for (zone, _, range) in zones {
            if range.contains(heartRate) {
                return zone
            }
        }
        return heartRate > maxHeartRate ? 5 : 1
    }

    // MARK: - Strain Calculation
    func calculateDayStrain(heartRateData: [HeartRateReading], workouts: [Workout], steps: Int) -> StrainScore {
        var totalStrain: Double = 0
        var cardiovascularLoad: Double = 0
        var muscularLoad: Double = 0

        // Calculate workout strain
        for workout in workouts {
            let workoutStrain = calculateWorkoutStrain(workout: workout, heartRateData: heartRateData)
            totalStrain += workoutStrain.strain
            cardiovascularLoad += workoutStrain.cardiovascular
            muscularLoad += workoutStrain.muscular
        }

        // Calculate non-workout strain from general heart rate data
        let backgroundStrain = calculateBackgroundStrain(heartRateData: heartRateData, excluding: workouts)
        totalStrain += backgroundStrain

        // Add steps strain
        let stepsStrain = calculateStepsStrain(steps: steps)
        totalStrain += stepsStrain

        // Apply Borg scale transformation
        let scaledStrain = applyBorgScaleTransformation(rawStrain: totalStrain)

        return StrainScore(
            date: Date(),
            score: min(21, scaledStrain),
            cardiovascularLoad: cardiovascularLoad,
            muscularLoad: muscularLoad,
            workouts: workouts,
            activeCalories: 0,
            steps: steps
        )
    }

    func calculateWorkoutStrain(workout: Workout, heartRateData: [HeartRateReading]? = nil) -> (strain: Double, cardiovascular: Double, muscular: Double) {
        let duration = workout.duration / 60 // Convert to minutes
        var cardiovascular: Double = 0
        var muscular: Double = 0

        // Calculate based on average heart rate if available
        if workout.averageHeartRate > 0 {
            let hrPercentage = (workout.averageHeartRate - restingHeartRate) / (maxHeartRate - restingHeartRate)
            let intensityFactor = pow(hrPercentage, 2) // Quadratic scaling for intensity

            cardiovascular = duration * intensityFactor * 0.15
        } else {
            // Estimate based on workout type
            cardiovascular = duration * getIntensityMultiplier(for: workout.type) * 0.1
        }

        // Muscular load varies by workout type
        muscular = duration * getMuscularLoadFactor(for: workout.type) * 0.05

        let totalStrain = cardiovascular + muscular

        return (totalStrain, cardiovascular, muscular)
    }

    func calculateLiveStrain(heartRateHistory: [HeartRateReading], workoutType: WorkoutType) -> Double {
        guard !heartRateHistory.isEmpty else { return 0 }

        var strain: Double = 0

        for i in 1..<heartRateHistory.count {
            let reading = heartRateHistory[i]
            let previousReading = heartRateHistory[i - 1]

            let duration = reading.timestamp.timeIntervalSince(previousReading.timestamp) / 60 // Minutes
            let hrPercentage = (reading.bpm - restingHeartRate) / (maxHeartRate - restingHeartRate)
            let intensityFactor = pow(max(0, hrPercentage), 2)

            strain += duration * intensityFactor * 0.15
        }

        // Apply type-specific multiplier
        strain *= getIntensityMultiplier(for: workoutType)

        return applyBorgScaleTransformation(rawStrain: strain)
    }

    // MARK: - Private Helpers
    private func calculateBackgroundStrain(heartRateData: [HeartRateReading], excluding workouts: [Workout]) -> Double {
        // Filter out heart rate data during workouts
        let workoutPeriods = workouts.compactMap { workout -> (start: Date, end: Date)? in
            guard let end = workout.endTime else { return nil }
            return (workout.startTime, end)
        }

        let backgroundReadings = heartRateData.filter { reading in
            !workoutPeriods.contains { period in
                reading.timestamp >= period.start && reading.timestamp <= period.end
            }
        }

        // Calculate strain from elevated heart rate periods
        var strain: Double = 0
        for reading in backgroundReadings {
            if reading.bpm > restingHeartRate + 20 {
                let hrPercentage = (reading.bpm - restingHeartRate) / (maxHeartRate - restingHeartRate)
                strain += pow(hrPercentage, 2) * 0.02 // Small contribution per reading
            }
        }

        return strain
    }

    private func calculateStepsStrain(steps: Int) -> Double {
        // 10,000 steps contributes about 2 strain points
        return Double(steps) / 10000 * 2
    }

    private func applyBorgScaleTransformation(rawStrain: Double) -> Double {
        // The Borg scale is non-linear - higher strain values are progressively harder to achieve
        // This matches the subjective perception of exertion

        if rawStrain <= 10 {
            return rawStrain
        } else if rawStrain <= 15 {
            // Moderate difficulty increase
            return 10 + (rawStrain - 10) * 0.8
        } else if rawStrain <= 20 {
            // Hard difficulty increase
            return 14 + (rawStrain - 15) * 0.6
        } else {
            // Very hard to reach maximum
            return 17 + (rawStrain - 20) * 0.4
        }
    }

    private func getIntensityMultiplier(for workoutType: WorkoutType) -> Double {
        switch workoutType {
        case .hiit, .crossfit, .boxing: return 1.4
        case .running, .cycling, .rowing: return 1.2
        case .swimming, .basketball, .soccer, .tennis: return 1.15
        case .weightTraining: return 1.0
        case .hiking, .elliptical, .stairClimber: return 0.9
        case .dance: return 0.85
        case .yoga, .pilates: return 0.5
        case .walking, .golf: return 0.4
        case .other: return 1.0
        }
    }

    private func getMuscularLoadFactor(for workoutType: WorkoutType) -> Double {
        switch workoutType {
        case .weightTraining, .crossfit: return 1.5
        case .hiit, .boxing: return 1.2
        case .rowing, .swimming: return 1.0
        case .running, .cycling, .hiking, .stairClimber: return 0.8
        case .basketball, .soccer, .tennis: return 0.7
        case .yoga, .pilates: return 0.5
        case .walking, .golf, .elliptical: return 0.3
        case .dance: return 0.6
        case .other: return 0.5
        }
    }

    // MARK: - Strain Coach
    func getOptimalStrainTarget(recovery: RecoveryScore, weeklyStrainHistory: [StrainScore]) -> StrainTarget {
        let recoveryCategory = recovery.category

        // Base target on recovery
        var targetMin: Double
        var targetMax: Double

        switch recoveryCategory {
        case .green:
            targetMin = 14
            targetMax = 21
        case .yellow:
            targetMin = 10
            targetMax = 14
        case .red:
            targetMin = 0
            targetMax = 10
        }

        // Adjust based on recent training load
        let recentAverage = weeklyStrainHistory.prefix(3).map { $0.score }.reduce(0, +) / max(1, Double(min(3, weeklyStrainHistory.count)))

        // If recent strain has been high, suggest more recovery
        if recentAverage > 15 && recoveryCategory != .green {
            targetMax = min(targetMax, 12)
        }

        // If strain has been low, suggest building up
        if recentAverage < 8 && recoveryCategory == .green {
            targetMin = max(targetMin, 12)
        }

        let description: String
        switch recoveryCategory {
        case .green:
            description = "Your recovery is excellent. Push yourself today!"
        case .yellow:
            description = "Moderate activity recommended. Listen to your body."
        case .red:
            description = "Focus on rest and recovery activities."
        }

        return StrainTarget(
            minStrain: targetMin,
            maxStrain: targetMax,
            currentRecovery: recovery.score,
            description: description
        )
    }

    func getTrainingZone(currentStrain: Double, target: StrainTarget) -> TrainingZone {
        if currentStrain < target.minStrain * 0.5 {
            return .restorative
        } else if currentStrain < target.minStrain {
            return .building
        } else if currentStrain <= target.maxStrain {
            return .optimal
        } else {
            return .overreaching
        }
    }
}

// MARK: - Supporting Types
struct StrainTarget {
    let minStrain: Double
    let maxStrain: Double
    let currentRecovery: Double
    let description: String

    var targetRange: ClosedRange<Double> {
        minStrain...maxStrain
    }
}

enum TrainingZone: String, CaseIterable {
    case restorative = "Restorative"
    case building = "Building"
    case optimal = "Optimal"
    case overreaching = "Overreaching"

    var color: Color {
        switch self {
        case .restorative: return .blue
        case .building: return .accentYellow
        case .optimal: return .accentGreen
        case .overreaching: return .accentRed
        }
    }

    var description: String {
        switch self {
        case .restorative: return "Light activity for active recovery"
        case .building: return "Building towards your target"
        case .optimal: return "You're in the sweet spot"
        case .overreaching: return "Consider backing off to prevent overtraining"
        }
    }
}

import SwiftUI

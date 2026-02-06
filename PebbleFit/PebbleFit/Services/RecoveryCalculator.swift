import Foundation

class RecoveryCalculator {
    static let shared = RecoveryCalculator()

    private let userDefaults = UserDefaults.standard

    // MARK: - Baselines
    var hrvBaseline: Double {
        get { userDefaults.double(forKey: "hrvBaseline") }
        set { userDefaults.set(newValue, forKey: "hrvBaseline") }
    }

    var rhrBaseline: Double {
        get { userDefaults.double(forKey: "rhrBaseline") }
        set { userDefaults.set(newValue, forKey: "rhrBaseline") }
    }

    var respiratoryRateBaseline: Double {
        get { userDefaults.double(forKey: "respiratoryRateBaseline") }
        set { userDefaults.set(newValue, forKey: "respiratoryRateBaseline") }
    }

    var calibrationDays: Int {
        get { userDefaults.integer(forKey: "calibrationDays") }
        set { userDefaults.set(newValue, forKey: "calibrationDays") }
    }

    var isCalibrated: Bool {
        calibrationDays >= 14
    }

    // MARK: - Recovery Calculation
    func calculateRecoveryScore(
        hrv: Double,
        restingHeartRate: Double,
        respiratoryRate: Double,
        sleepPerformance: Double,
        previousDayStrain: Double? = nil
    ) -> RecoveryScore {
        // Component weights
        let hrvWeight = 0.35
        let rhrWeight = 0.20
        let respiratoryWeight = 0.10
        let sleepWeight = 0.35

        // Calculate HRV score
        let hrvScore = calculateHRVScore(hrv)

        // Calculate RHR score
        let rhrScore = calculateRHRScore(restingHeartRate)

        // Calculate respiratory rate score
        let respiratoryScore = calculateRespiratoryScore(respiratoryRate)

        // Sleep performance is already 0-100
        let sleepScore = sleepPerformance

        // Weighted average
        var recoveryScore = (hrvScore * hrvWeight) +
                           (rhrScore * rhrWeight) +
                           (respiratoryScore * respiratoryWeight) +
                           (sleepScore * sleepWeight)

        // Apply strain adjustment if available
        if let strain = previousDayStrain {
            let strainAdjustment = calculateStrainAdjustment(strain: strain)
            recoveryScore = recoveryScore * strainAdjustment
        }

        // Ensure score is in valid range
        recoveryScore = min(100, max(0, recoveryScore))

        return RecoveryScore(
            date: Date(),
            score: recoveryScore,
            hrv: hrv,
            restingHeartRate: restingHeartRate,
            respiratoryRate: respiratoryRate,
            sleepPerformance: sleepPerformance
        )
    }

    // MARK: - Component Calculations
    private func calculateHRVScore(_ hrv: Double) -> Double {
        if hrvBaseline <= 0 {
            // No baseline yet, use population average as reference
            let populationAverage = 50.0
            return min(100, (hrv / populationAverage) * 70)
        }

        // Calculate deviation from personal baseline
        let deviation = (hrv - hrvBaseline) / hrvBaseline

        // Score based on deviation
        // +20% above baseline = 100 score
        // At baseline = 70 score
        // -30% below baseline = 0 score
        var score: Double
        if deviation >= 0 {
            score = 70 + (deviation / 0.2) * 30
        } else {
            score = 70 + (deviation / 0.3) * 70
        }

        return min(100, max(0, score))
    }

    private func calculateRHRScore(_ rhr: Double) -> Double {
        if rhrBaseline <= 0 {
            // No baseline, use general fitness reference
            // Lower RHR is generally better
            // 40 bpm = excellent, 80 bpm = needs improvement
            return max(0, 100 - ((rhr - 40) / 40) * 100)
        }

        // Calculate deviation from personal baseline
        // Lower than baseline is good, higher is bad
        let deviation = (rhrBaseline - rhr) / rhrBaseline

        var score: Double
        if deviation >= 0 {
            // RHR is lower than baseline (good)
            score = 70 + (deviation / 0.1) * 30
        } else {
            // RHR is higher than baseline (bad)
            score = 70 + (deviation / 0.2) * 70
        }

        return min(100, max(0, score))
    }

    private func calculateRespiratoryScore(_ rate: Double) -> Double {
        // Normal respiratory rate is 12-20 breaths per minute
        // Optimal is around 12-14 during sleep
        let optimalRate = 13.0
        let deviation = abs(rate - optimalRate)

        // Score decreases as rate deviates from optimal
        let score = 100 - (deviation * 10)
        return min(100, max(0, score))
    }

    private func calculateStrainAdjustment(strain: Double) -> Double {
        // High strain requires more recovery
        // Adjustment factor: 0.8 for 21 strain, 1.0 for 0 strain
        let adjustmentFactor = 1.0 - (strain / 21) * 0.2
        return max(0.8, adjustmentFactor)
    }

    // MARK: - Baseline Updates
    func updateBaselines(hrv: Double, rhr: Double, respiratoryRate: Double) {
        let days = calibrationDays

        if days < 30 {
            // During calibration period, use rolling average
            if hrvBaseline == 0 {
                hrvBaseline = hrv
            } else {
                hrvBaseline = (hrvBaseline * Double(days) + hrv) / Double(days + 1)
            }

            if rhrBaseline == 0 {
                rhrBaseline = rhr
            } else {
                rhrBaseline = (rhrBaseline * Double(days) + rhr) / Double(days + 1)
            }

            if respiratoryRateBaseline == 0 {
                respiratoryRateBaseline = respiratoryRate
            } else {
                respiratoryRateBaseline = (respiratoryRateBaseline * Double(days) + respiratoryRate) / Double(days + 1)
            }

            calibrationDays = days + 1
        } else {
            // After calibration, use slow-moving average to adapt to fitness changes
            let adaptationFactor = 0.02 // 2% weight to new data
            hrvBaseline = hrvBaseline * (1 - adaptationFactor) + hrv * adaptationFactor
            rhrBaseline = rhrBaseline * (1 - adaptationFactor) + rhr * adaptationFactor
            respiratoryRateBaseline = respiratoryRateBaseline * (1 - adaptationFactor) + respiratoryRate * adaptationFactor
        }
    }

    // MARK: - Recovery Recommendations
    func getRecommendation(for recovery: RecoveryScore) -> RecoveryRecommendation {
        let category = recovery.category

        switch category {
        case .green:
            return RecoveryRecommendation(
                title: "Primed for Performance",
                description: "Your body is well-recovered and ready for high-intensity training.",
                suggestedStrainRange: 14...21,
                activities: [.hiit, .running, .crossfit, .weightTraining],
                tips: [
                    "Great day for a PR attempt",
                    "Focus on high-intensity intervals",
                    "Challenge yourself with heavy lifts"
                ]
            )

        case .yellow:
            return RecoveryRecommendation(
                title: "Moderate Activity Recommended",
                description: "You're partially recovered. Listen to your body during activity.",
                suggestedStrainRange: 10...14,
                activities: [.cycling, .swimming, .yoga, .walking],
                tips: [
                    "Focus on technique over intensity",
                    "Consider active recovery activities",
                    "Stay hydrated and well-nourished"
                ]
            )

        case .red:
            return RecoveryRecommendation(
                title: "Prioritize Recovery",
                description: "Your body needs rest. Focus on recovery activities today.",
                suggestedStrainRange: 0...10,
                activities: [.yoga, .walking, .pilates],
                tips: [
                    "Focus on sleep and nutrition",
                    "Light stretching or mobility work",
                    "Consider a rest day",
                    "Check for signs of overtraining"
                ]
            )
        }
    }
}

// MARK: - Recovery Recommendation
struct RecoveryRecommendation {
    let title: String
    let description: String
    let suggestedStrainRange: ClosedRange<Double>
    let activities: [WorkoutType]
    let tips: [String]
}

import Foundation
import SwiftUI

// MARK: - Recovery Score
struct RecoveryScore: Identifiable, Codable {
    let id: UUID
    let date: Date
    let score: Double // 0-100
    let hrv: Double // Heart Rate Variability in ms
    let restingHeartRate: Double // BPM
    let respiratoryRate: Double // Breaths per minute
    let sleepPerformance: Double // 0-100
    let skinTemperature: Double? // Deviation from baseline
    let bloodOxygen: Double? // SpO2 percentage

    var category: RecoveryCategory {
        switch score {
        case 67...100: return .green
        case 34..<67: return .yellow
        default: return .red
        }
    }

    init(id: UUID = UUID(), date: Date = Date(), score: Double, hrv: Double,
         restingHeartRate: Double, respiratoryRate: Double, sleepPerformance: Double,
         skinTemperature: Double? = nil, bloodOxygen: Double? = nil) {
        self.id = id
        self.date = date
        self.score = score
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.respiratoryRate = respiratoryRate
        self.sleepPerformance = sleepPerformance
        self.skinTemperature = skinTemperature
        self.bloodOxygen = bloodOxygen
    }
}

enum RecoveryCategory: String, CaseIterable {
    case green = "Green"
    case yellow = "Yellow"
    case red = "Red"

    var color: Color {
        switch self {
        case .green: return .accentGreen
        case .yellow: return .accentYellow
        case .red: return .accentRed
        }
    }

    var description: String {
        switch self {
        case .green: return "Primed for high strain"
        case .yellow: return "Ready for moderate strain"
        case .red: return "Prioritize rest"
        }
    }

    var recommendation: String {
        switch self {
        case .green: return "Your body is well-recovered. Today is a great day for high-intensity training."
        case .yellow: return "You're moderately recovered. Consider moderate activity and monitor how you feel."
        case .red: return "Your body needs rest. Focus on recovery activities like light stretching or rest."
        }
    }
}

// MARK: - Strain Score
struct StrainScore: Identifiable, Codable {
    let id: UUID
    let date: Date
    var score: Double // 0-21 (Borg scale based)
    var cardiovascularLoad: Double
    var muscularLoad: Double
    var workouts: [Workout]
    var activeCalories: Double
    var steps: Int

    var category: StrainCategory {
        switch score {
        case 18...21: return .allOut
        case 14..<18: return .high
        case 10..<14: return .moderate
        default: return .light
        }
    }

    init(id: UUID = UUID(), date: Date = Date(), score: Double = 0, cardiovascularLoad: Double = 0,
         muscularLoad: Double = 0, workouts: [Workout] = [], activeCalories: Double = 0, steps: Int = 0) {
        self.id = id
        self.date = date
        self.score = score
        self.cardiovascularLoad = cardiovascularLoad
        self.muscularLoad = muscularLoad
        self.workouts = workouts
        self.activeCalories = activeCalories
        self.steps = steps
    }
}

enum StrainCategory: String, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case high = "High"
    case allOut = "All Out"

    var color: Color {
        switch self {
        case .light: return .blue
        case .moderate: return .accentYellow
        case .high: return .orange
        case .allOut: return .accentRed
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .light: return 0...9
        case .moderate: return 10...13
        case .high: return 14...17
        case .allOut: return 18...21
        }
    }

    var description: String {
        switch self {
        case .light: return "Minimal stress, active recovery"
        case .moderate: return "Maintains fitness"
        case .high: return "Builds fitness gains"
        case .allOut: return "Significant stress"
        }
    }
}

// MARK: - Workout
struct Workout: Identifiable, Codable {
    let id: UUID
    let type: WorkoutType
    let startTime: Date
    var endTime: Date?
    var strain: Double
    var averageHeartRate: Double
    var maxHeartRate: Double
    var calories: Double
    var duration: TimeInterval
    var heartRateZones: [HeartRateZone]
    var isAutoDetected: Bool

    init(id: UUID = UUID(), type: WorkoutType, startTime: Date = Date(), endTime: Date? = nil,
         strain: Double = 0, averageHeartRate: Double = 0, maxHeartRate: Double = 0,
         calories: Double = 0, duration: TimeInterval = 0, heartRateZones: [HeartRateZone] = [],
         isAutoDetected: Bool = false) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.strain = strain
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.calories = calories
        self.duration = duration
        self.heartRateZones = heartRateZones
        self.isAutoDetected = isAutoDetected
    }
}

enum WorkoutType: String, Codable, CaseIterable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case weightTraining = "Weight Training"
    case hiit = "HIIT"
    case yoga = "Yoga"
    case walking = "Walking"
    case hiking = "Hiking"
    case rowing = "Rowing"
    case crossfit = "CrossFit"
    case basketball = "Basketball"
    case soccer = "Soccer"
    case tennis = "Tennis"
    case golf = "Golf"
    case boxing = "Boxing"
    case pilates = "Pilates"
    case dance = "Dance"
    case elliptical = "Elliptical"
    case stairClimber = "Stair Climber"
    case other = "Other"

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .weightTraining: return "dumbbell.fill"
        case .hiit: return "flame.fill"
        case .yoga: return "figure.yoga"
        case .walking: return "figure.walk"
        case .hiking: return "figure.hiking"
        case .rowing: return "figure.rowing"
        case .crossfit: return "figure.strengthtraining.functional"
        case .basketball: return "figure.basketball"
        case .soccer: return "figure.soccer"
        case .tennis: return "figure.tennis"
        case .golf: return "figure.golf"
        case .boxing: return "figure.boxing"
        case .pilates: return "figure.pilates"
        case .dance: return "figure.dance"
        case .elliptical: return "figure.elliptical"
        case .stairClimber: return "figure.stair.stepper"
        case .other: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .running, .hiking, .walking: return .orange
        case .cycling, .rowing, .elliptical: return .blue
        case .swimming: return .cyan
        case .weightTraining, .crossfit: return .purple
        case .hiit, .boxing: return .red
        case .yoga, .pilates: return .green
        case .basketball, .soccer, .tennis, .golf: return .yellow
        case .dance: return .pink
        case .stairClimber: return .indigo
        case .other: return .gray
        }
    }
}

struct HeartRateZone: Identifiable, Codable {
    let id: UUID
    let zone: Int // 1-5
    let duration: TimeInterval
    let percentage: Double

    var name: String {
        switch zone {
        case 1: return "Recovery"
        case 2: return "Fat Burn"
        case 3: return "Cardio"
        case 4: return "Hard"
        case 5: return "Peak"
        default: return "Unknown"
        }
    }

    var color: Color {
        switch zone {
        case 1: return .gray
        case 2: return .blue
        case 3: return .green
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }

    init(id: UUID = UUID(), zone: Int, duration: TimeInterval, percentage: Double) {
        self.id = id
        self.zone = zone
        self.duration = duration
        self.percentage = percentage
    }
}

// MARK: - Sleep Data
struct SleepData: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bedTime: Date
    let wakeTime: Date
    var totalDuration: TimeInterval // Total time in bed
    var sleepDuration: TimeInterval // Actual sleep time
    var stages: [SleepStage]
    var efficiency: Double // 0-100
    var performance: Double // 0-100 (time slept vs sleep needed)
    var consistency: Double // 0-100
    var latency: TimeInterval // Time to fall asleep
    var disturbances: Int
    var sleepDebt: TimeInterval
    var sleepNeed: TimeInterval

    var lightSleep: TimeInterval {
        stages.filter { $0.stage == .light }.reduce(0) { $0 + $1.duration }
    }

    var deepSleep: TimeInterval {
        stages.filter { $0.stage == .deep }.reduce(0) { $0 + $1.duration }
    }

    var remSleep: TimeInterval {
        stages.filter { $0.stage == .rem }.reduce(0) { $0 + $1.duration }
    }

    var awakeTime: TimeInterval {
        stages.filter { $0.stage == .awake }.reduce(0) { $0 + $1.duration }
    }

    init(id: UUID = UUID(), date: Date = Date(), bedTime: Date, wakeTime: Date,
         totalDuration: TimeInterval = 0, sleepDuration: TimeInterval = 0,
         stages: [SleepStage] = [], efficiency: Double = 0, performance: Double = 0,
         consistency: Double = 0, latency: TimeInterval = 0, disturbances: Int = 0,
         sleepDebt: TimeInterval = 0, sleepNeed: TimeInterval = 8 * 3600) {
        self.id = id
        self.date = date
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.totalDuration = totalDuration
        self.sleepDuration = sleepDuration
        self.stages = stages
        self.efficiency = efficiency
        self.performance = performance
        self.consistency = consistency
        self.latency = latency
        self.disturbances = disturbances
        self.sleepDebt = sleepDebt
        self.sleepNeed = sleepNeed
    }
}

struct SleepStage: Identifiable, Codable {
    let id: UUID
    let stage: SleepStageType
    let startTime: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), stage: SleepStageType, startTime: Date, duration: TimeInterval) {
        self.id = id
        self.stage = stage
        self.startTime = startTime
        self.duration = duration
    }
}

enum SleepStageType: String, Codable, CaseIterable {
    case awake = "Awake"
    case light = "Light"
    case deep = "Deep"
    case rem = "REM"

    var color: Color {
        switch self {
        case .awake: return .red
        case .light: return .blue
        case .deep: return .purple
        case .rem: return .cyan
        }
    }

    var description: String {
        switch self {
        case .awake: return "Awake periods during the night"
        case .light: return "Light sleep for memory consolidation"
        case .deep: return "Deep sleep for physical recovery"
        case .rem: return "REM sleep for cognitive restoration"
        }
    }
}

// MARK: - Heart Rate Data
struct HeartRateReading: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let bpm: Double
    let context: HeartRateContext

    init(id: UUID = UUID(), timestamp: Date = Date(), bpm: Double, context: HeartRateContext = .resting) {
        self.id = id
        self.timestamp = timestamp
        self.bpm = bpm
        self.context = context
    }
}

enum HeartRateContext: String, Codable {
    case resting = "Resting"
    case active = "Active"
    case workout = "Workout"
    case sleep = "Sleep"
}

// MARK: - HRV Data
struct HRVReading: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let value: Double // RMSSD in milliseconds
    let context: HRVContext

    init(id: UUID = UUID(), timestamp: Date = Date(), value: Double, context: HRVContext = .morning) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.context = context
    }
}

enum HRVContext: String, Codable {
    case morning = "Morning"
    case sleep = "Sleep"
    case recovery = "Recovery"
}

// MARK: - Journal Entry
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var behaviors: [BehaviorEntry]
    var notes: String

    init(id: UUID = UUID(), date: Date = Date(), behaviors: [BehaviorEntry] = [], notes: String = "") {
        self.id = id
        self.date = date
        self.behaviors = behaviors
        self.notes = notes
    }
}

struct BehaviorEntry: Identifiable, Codable {
    let id: UUID
    let behavior: Behavior
    var value: BehaviorValue
    var details: String?

    init(id: UUID = UUID(), behavior: Behavior, value: BehaviorValue, details: String? = nil) {
        self.id = id
        self.behavior = behavior
        self.value = value
        self.details = details
    }
}

enum BehaviorValue: Codable {
    case boolean(Bool)
    case number(Double)
    case scale(Int) // 1-5
    case time(Date)

    var displayValue: String {
        switch self {
        case .boolean(let val): return val ? "Yes" : "No"
        case .number(let val): return String(format: "%.1f", val)
        case .scale(let val): return "\(val)/5"
        case .time(let val):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: val)
        }
    }
}

enum BehaviorCategory: String, Codable, CaseIterable {
    case recovery = "Recovery"
    case sleep = "Sleep"
    case nutrition = "Nutrition"
    case substances = "Substances"
    case mentalHealth = "Mental Health"
    case medication = "Medication"
    case lifestyle = "Lifestyle"

    var icon: String {
        switch self {
        case .recovery: return "arrow.counterclockwise.circle.fill"
        case .sleep: return "moon.fill"
        case .nutrition: return "fork.knife"
        case .substances: return "cup.and.saucer.fill"
        case .mentalHealth: return "brain.head.profile"
        case .medication: return "pills.fill"
        case .lifestyle: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .recovery: return .green
        case .sleep: return .purple
        case .nutrition: return .orange
        case .substances: return .red
        case .mentalHealth: return .blue
        case .medication: return .pink
        case .lifestyle: return .cyan
        }
    }
}

struct Behavior: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: BehaviorCategory
    let valueType: BehaviorValueType

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Behavior, rhs: Behavior) -> Bool {
        lhs.id == rhs.id
    }

    init(id: UUID = UUID(), name: String, category: BehaviorCategory, valueType: BehaviorValueType) {
        self.id = id
        self.name = name
        self.category = category
        self.valueType = valueType
    }
}

enum BehaviorValueType: String, Codable {
    case boolean
    case number
    case scale
    case time
}

// MARK: - User Profile
struct UserProfile: Codable {
    var id: UUID
    var name: String
    var email: String?
    var dateOfBirth: Date?
    var gender: Gender?
    var height: Double? // in cm
    var weight: Double? // in kg
    var maxHeartRate: Int?
    var restingHeartRateBaseline: Double?
    var hrvBaseline: Double?
    var sleepGoal: TimeInterval
    var strainGoal: Double
    var createdAt: Date
    var calibrationComplete: Bool

    init(id: UUID = UUID(), name: String = "", email: String? = nil, dateOfBirth: Date? = nil,
         gender: Gender? = nil, height: Double? = nil, weight: Double? = nil,
         maxHeartRate: Int? = nil, restingHeartRateBaseline: Double? = nil,
         hrvBaseline: Double? = nil, sleepGoal: TimeInterval = 8 * 3600,
         strainGoal: Double = 14, createdAt: Date = Date(), calibrationComplete: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height
        self.weight = weight
        self.maxHeartRate = maxHeartRate
        self.restingHeartRateBaseline = restingHeartRateBaseline
        self.hrvBaseline = hrvBaseline
        self.sleepGoal = sleepGoal
        self.strainGoal = strainGoal
        self.createdAt = createdAt
        self.calibrationComplete = calibrationComplete
    }

    var calculatedMaxHeartRate: Int {
        if let maxHR = maxHeartRate {
            return maxHR
        }
        guard let dob = dateOfBirth else { return 190 }
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 30
        return 220 - age
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}

// MARK: - Weekly Assessment
struct WeeklyAssessment: Identifiable, Codable {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date
    var averageRecovery: Double
    var averageStrain: Double
    var averageSleepPerformance: Double
    var totalWorkouts: Int
    var strainBalance: StrainBalance
    var sleepTrend: Trend
    var recoveryTrend: Trend
    var insights: [String]

    init(id: UUID = UUID(), weekStartDate: Date, weekEndDate: Date, averageRecovery: Double = 0,
         averageStrain: Double = 0, averageSleepPerformance: Double = 0, totalWorkouts: Int = 0,
         strainBalance: StrainBalance = .optimal, sleepTrend: Trend = .stable,
         recoveryTrend: Trend = .stable, insights: [String] = []) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.averageRecovery = averageRecovery
        self.averageStrain = averageStrain
        self.averageSleepPerformance = averageSleepPerformance
        self.totalWorkouts = totalWorkouts
        self.strainBalance = strainBalance
        self.sleepTrend = sleepTrend
        self.recoveryTrend = recoveryTrend
        self.insights = insights
    }
}

enum StrainBalance: String, Codable {
    case restoring = "Restoring"
    case optimal = "Optimal"
    case overreaching = "Overreaching"

    var color: Color {
        switch self {
        case .restoring: return .blue
        case .optimal: return .accentGreen
        case .overreaching: return .orange
        }
    }
}

enum Trend: String, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .accentGreen
        case .stable: return .accentYellow
        case .declining: return .accentRed
        }
    }
}

// MARK: - Stress Level
struct StressReading: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: Double // 0-3 scale
    let hrv: Double
    let heartRate: Double

    var category: StressCategory {
        switch level {
        case 0..<1: return .low
        case 1..<2: return .moderate
        case 2..<3: return .high
        default: return .veryHigh
        }
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), level: Double, hrv: Double, heartRate: Double) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.hrv = hrv
        self.heartRate = heartRate
    }
}

enum StressCategory: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"

    var color: Color {
        switch self {
        case .low: return .accentGreen
        case .moderate: return .accentYellow
        case .high: return .orange
        case .veryHigh: return .accentRed
        }
    }
}

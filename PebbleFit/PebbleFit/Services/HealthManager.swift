import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    static let shared = HealthManager()

    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var todayRecovery: RecoveryScore?
    @Published var todayStrain: StrainScore?
    @Published var lastNightSleep: SleepData?
    @Published var currentHeartRate: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var latestHRV: Double = 0
    @Published var todaySteps: Int = 0
    @Published var todayCalories: Double = 0
    @Published var weeklyRecoveries: [RecoveryScore] = []
    @Published var weeklyStrains: [StrainScore] = []
    @Published var weeklySleepData: [SleepData] = []

    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard

    // Health data types to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .vo2Max)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]

    // Health data types to write
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]

    // MARK: - Initialization
    private init() {
        setupBluetoothSubscriptions()
        loadCachedData()
    }

    // MARK: - Authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.startObservingHealthData()
                    self?.fetchAllHealthData()
                }
                completion(success)
            }
        }
    }

    // MARK: - Data Fetching
    func fetchAllHealthData() {
        fetchTodayHeartRate()
        fetchRestingHeartRate()
        fetchLatestHRV()
        fetchTodaySteps()
        fetchTodayCalories()
        fetchLastNightSleep()
        calculateTodayRecovery()
        calculateTodayStrain()
        fetchWeeklyData()
    }

    func fetchTodayHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))

            DispatchQueue.main.async {
                self?.currentHeartRate = heartRate
            }
        }

        healthStore.execute(query)
    }

    func fetchRestingHeartRate() {
        let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: restingHRType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let rhr = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))

            DispatchQueue.main.async {
                self?.restingHeartRate = rhr
            }
        }

        healthStore.execute(query)
    }

    func fetchLatestHRV() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))

            DispatchQueue.main.async {
                self?.latestHRV = hrv
            }
        }

        healthStore.execute(query)
    }

    func fetchTodaySteps() {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let steps = Int(sum.doubleValue(for: HKUnit.count()))

            DispatchQueue.main.async {
                self?.todaySteps = steps
            }
        }

        healthStore.execute(query)
    }

    func fetchTodayCalories() {
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())

            DispatchQueue.main.async {
                self?.todayCalories = calories
            }
        }

        healthStore.execute(query)
    }

    func fetchLastNightSleep() {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else { return }

            self?.processSleepSamples(sleepSamples)
        }

        healthStore.execute(query)
    }

    private func processSleepSamples(_ samples: [HKCategorySample]) {
        var stages: [SleepStage] = []
        var totalSleep: TimeInterval = 0
        var bedTime: Date?
        var wakeTime: Date?
        var disturbances = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            if bedTime == nil || sample.startDate < bedTime! {
                bedTime = sample.startDate
            }
            if wakeTime == nil || sample.endDate > wakeTime! {
                wakeTime = sample.endDate
            }

            let stageType: SleepStageType
            switch sample.value {
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                stageType = .awake
                disturbances += 1
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                stageType = .light
                totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                stageType = .deep
                totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                stageType = .rem
                totalSleep += duration
            default:
                stageType = .light
                totalSleep += duration
            }

            stages.append(SleepStage(stage: stageType, startTime: sample.startDate, duration: duration))
        }

        guard let bed = bedTime, let wake = wakeTime else { return }

        let totalDuration = wake.timeIntervalSince(bed)
        let efficiency = totalSleep / totalDuration * 100
        let sleepNeed: TimeInterval = 8 * 3600 // 8 hours
        let performance = min(100, totalSleep / sleepNeed * 100)

        let sleepData = SleepData(
            date: bed,
            bedTime: bed,
            wakeTime: wake,
            totalDuration: totalDuration,
            sleepDuration: totalSleep,
            stages: stages,
            efficiency: efficiency,
            performance: performance,
            consistency: 85, // Would need historical data to calculate
            latency: stages.first?.duration ?? 0,
            disturbances: disturbances,
            sleepDebt: max(0, sleepNeed - totalSleep),
            sleepNeed: sleepNeed
        )

        DispatchQueue.main.async {
            self.lastNightSleep = sleepData
        }
    }

    // MARK: - Recovery Calculation
    func calculateTodayRecovery() {
        // Recovery score calculation based on HRV, RHR, respiratory rate, and sleep
        // This is a simplified algorithm - Whoop uses more sophisticated ML models

        let hrvBaseline = userDefaults.double(forKey: "hrvBaseline")
        let rhrBaseline = userDefaults.double(forKey: "rhrBaseline")

        // Use current values or defaults
        let currentHRV = latestHRV > 0 ? latestHRV : 50
        let currentRHR = restingHeartRate > 0 ? restingHeartRate : 60
        let sleepPerformance = lastNightSleep?.performance ?? 70

        // Calculate component scores
        var hrvScore: Double = 50
        if hrvBaseline > 0 {
            let hrvDeviation = (currentHRV - hrvBaseline) / hrvBaseline
            hrvScore = min(100, max(0, 50 + hrvDeviation * 50))
        } else {
            hrvScore = min(100, currentHRV / 100 * 100)
        }

        var rhrScore: Double = 50
        if rhrBaseline > 0 {
            let rhrDeviation = (rhrBaseline - currentRHR) / rhrBaseline
            rhrScore = min(100, max(0, 50 + rhrDeviation * 100))
        } else {
            rhrScore = max(0, 100 - (currentRHR - 40))
        }

        // Weight the components
        let recoveryScore = (hrvScore * 0.35) + (rhrScore * 0.25) + (sleepPerformance * 0.40)

        let recovery = RecoveryScore(
            date: Date(),
            score: recoveryScore,
            hrv: currentHRV,
            restingHeartRate: currentRHR,
            respiratoryRate: 14.5, // Default value
            sleepPerformance: sleepPerformance
        )

        DispatchQueue.main.async {
            self.todayRecovery = recovery
        }

        // Update baselines if this is early calibration period
        updateBaselines(hrv: currentHRV, rhr: currentRHR)
    }

    private func updateBaselines(hrv: Double, rhr: Double) {
        let calibrationDays = userDefaults.integer(forKey: "calibrationDays")

        if calibrationDays < 30 {
            let currentHRVBaseline = userDefaults.double(forKey: "hrvBaseline")
            let currentRHRBaseline = userDefaults.double(forKey: "rhrBaseline")

            if currentHRVBaseline == 0 {
                userDefaults.set(hrv, forKey: "hrvBaseline")
            } else {
                // Rolling average
                let newHRVBaseline = (currentHRVBaseline * Double(calibrationDays) + hrv) / Double(calibrationDays + 1)
                userDefaults.set(newHRVBaseline, forKey: "hrvBaseline")
            }

            if currentRHRBaseline == 0 {
                userDefaults.set(rhr, forKey: "rhrBaseline")
            } else {
                let newRHRBaseline = (currentRHRBaseline * Double(calibrationDays) + rhr) / Double(calibrationDays + 1)
                userDefaults.set(newRHRBaseline, forKey: "rhrBaseline")
            }

            userDefaults.set(calibrationDays + 1, forKey: "calibrationDays")
        }
    }

    // MARK: - Strain Calculation
    func calculateTodayStrain() {
        // Strain is calculated based on heart rate data throughout the day
        // Uses a modified Borg scale (0-21)

        fetchTodayWorkouts { [weak self] workouts in
            guard let self = self else { return }

            var totalStrain: Double = 0
            var cardiovascularLoad: Double = 0
            var muscularLoad: Double = 0

            // Calculate workout strain
            for workout in workouts {
                let workoutStrain = self.calculateWorkoutStrain(workout)
                totalStrain += workoutStrain
                cardiovascularLoad += workoutStrain * 0.7
                muscularLoad += workoutStrain * 0.3
            }

            // Add baseline daily activity strain
            let stepsStrain = Double(self.todaySteps) / 10000 * 2 // Up to 2 strain points for 10k steps
            totalStrain += stepsStrain

            // Apply non-linear scaling (Borg scale)
            let scaledStrain = self.applyBorgScale(totalStrain)

            let strainScore = StrainScore(
                date: Date(),
                score: min(21, scaledStrain),
                cardiovascularLoad: cardiovascularLoad,
                muscularLoad: muscularLoad,
                workouts: workouts,
                activeCalories: self.todayCalories,
                steps: self.todaySteps
            )

            DispatchQueue.main.async {
                self.todayStrain = strainScore
            }
        }
    }

    private func calculateWorkoutStrain(_ workout: Workout) -> Double {
        // Simplified strain calculation based on duration and intensity
        let durationMinutes = workout.duration / 60
        let intensityFactor = workout.averageHeartRate / 180 // Normalized to max HR

        var strain = (durationMinutes / 60) * intensityFactor * 10

        // Adjust based on workout type
        switch workout.type {
        case .hiit, .crossfit, .boxing:
            strain *= 1.3
        case .running, .cycling, .swimming:
            strain *= 1.1
        case .yoga, .pilates, .walking:
            strain *= 0.7
        default:
            break
        }

        return strain
    }

    private func applyBorgScale(_ rawStrain: Double) -> Double {
        // Non-linear scaling to match Borg scale perception
        // Higher strain values are harder to achieve
        if rawStrain <= 10 {
            return rawStrain
        } else if rawStrain <= 15 {
            return 10 + (rawStrain - 10) * 0.8
        } else {
            return 14 + (rawStrain - 15) * 0.5
        }
    }

    func fetchTodayWorkouts(completion: @escaping ([Workout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let workoutSamples = samples as? [HKWorkout] else {
                completion([])
                return
            }

            let workouts = workoutSamples.map { hkWorkout -> Workout in
                let workoutType = self.mapHKWorkoutType(hkWorkout.workoutActivityType)
                let duration = hkWorkout.duration
                let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0

                return Workout(
                    type: workoutType,
                    startTime: hkWorkout.startDate,
                    endTime: hkWorkout.endDate,
                    strain: 0, // Calculated later
                    averageHeartRate: 0, // Would need to query HR during workout
                    maxHeartRate: 0,
                    calories: calories,
                    duration: duration,
                    heartRateZones: [],
                    isAutoDetected: false
                )
            }

            completion(workouts)
        }

        healthStore.execute(query)
    }

    private func mapHKWorkoutType(_ activityType: HKWorkoutActivityType) -> WorkoutType {
        switch activityType {
        case .running: return .running
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .traditionalStrengthTraining, .functionalStrengthTraining: return .weightTraining
        case .highIntensityIntervalTraining: return .hiit
        case .yoga: return .yoga
        case .walking: return .walking
        case .hiking: return .hiking
        case .rowing: return .rowing
        case .crossTraining: return .crossfit
        case .basketball: return .basketball
        case .soccer: return .soccer
        case .tennis: return .tennis
        case .golf: return .golf
        case .boxing: return .boxing
        case .pilates: return .pilates
        case .dance: return .dance
        case .elliptical: return .elliptical
        case .stairClimbing: return .stairClimber
        default: return .other
        }
    }

    // MARK: - Weekly Data
    func fetchWeeklyData() {
        let calendar = Calendar.current
        let now = Date()

        // Generate sample weekly data (in production, this would fetch from stored data)
        var recoveries: [RecoveryScore] = []
        var strains: [StrainScore] = []
        var sleepData: [SleepData] = []

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }

            // Sample recovery
            let recoveryScore = Double.random(in: 40...90)
            recoveries.append(RecoveryScore(
                date: date,
                score: recoveryScore,
                hrv: Double.random(in: 30...80),
                restingHeartRate: Double.random(in: 50...70),
                respiratoryRate: Double.random(in: 12...18),
                sleepPerformance: Double.random(in: 60...95)
            ))

            // Sample strain
            strains.append(StrainScore(
                date: date,
                score: Double.random(in: 5...18),
                cardiovascularLoad: Double.random(in: 3...12),
                muscularLoad: Double.random(in: 2...8),
                workouts: [],
                activeCalories: Double.random(in: 200...800),
                steps: Int.random(in: 3000...15000)
            ))

            // Sample sleep
            let bedTime = calendar.date(bySettingHour: 22, minute: Int.random(in: 0...59), second: 0, of: date)!
            let wakeTime = calendar.date(byAdding: .hour, value: Int.random(in: 6...9), to: bedTime)!

            sleepData.append(SleepData(
                date: date,
                bedTime: bedTime,
                wakeTime: wakeTime,
                totalDuration: wakeTime.timeIntervalSince(bedTime),
                sleepDuration: Double.random(in: 5...8) * 3600,
                stages: [],
                efficiency: Double.random(in: 75...95),
                performance: Double.random(in: 60...100),
                consistency: Double.random(in: 70...95),
                latency: Double.random(in: 5...30) * 60,
                disturbances: Int.random(in: 0...5),
                sleepDebt: Double.random(in: 0...2) * 3600,
                sleepNeed: 8 * 3600
            ))
        }

        DispatchQueue.main.async {
            self.weeklyRecoveries = recoveries
            self.weeklyStrains = strains
            self.weeklySleepData = sleepData
        }
    }

    // MARK: - Data Writing
    func saveHeartRate(_ bpm: Double, date: Date = Date()) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: bpm)
        let sample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving heart rate: \(error)")
            }
        }
    }

    func saveHRV(_ ms: Double, date: Date = Date()) {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvQuantity = HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: ms)
        let sample = HKQuantitySample(type: hrvType, quantity: hrvQuantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            if let error = error {
                print("Error saving HRV: \(error)")
            }
        }
    }

    func saveWorkout(_ workout: Workout) {
        let hkWorkoutType = mapWorkoutTypeToHK(workout.type)

        let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: HKWorkoutConfiguration(), device: nil)

        workoutBuilder.beginCollection(withStart: workout.startTime) { success, error in
            guard success else { return }

            workoutBuilder.endCollection(withEnd: workout.endTime ?? Date()) { success, error in
                guard success else { return }

                workoutBuilder.finishWorkout { hkWorkout, error in
                    if let error = error {
                        print("Error saving workout: \(error)")
                    }
                }
            }
        }
    }

    private func mapWorkoutTypeToHK(_ type: WorkoutType) -> HKWorkoutActivityType {
        switch type {
        case .running: return .running
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .weightTraining: return .traditionalStrengthTraining
        case .hiit: return .highIntensityIntervalTraining
        case .yoga: return .yoga
        case .walking: return .walking
        case .hiking: return .hiking
        case .rowing: return .rowing
        case .crossfit: return .crossTraining
        case .basketball: return .basketball
        case .soccer: return .soccer
        case .tennis: return .tennis
        case .golf: return .golf
        case .boxing: return .boxing
        case .pilates: return .pilates
        case .dance: return .dance
        case .elliptical: return .elliptical
        case .stairClimber: return .stairClimbing
        case .other: return .other
        }
    }

    // MARK: - Observation
    private func startObservingHealthData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                self?.fetchTodayHeartRate()
            }
        }

        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { _, _ in }
    }

    // MARK: - Bluetooth Integration
    private func setupBluetoothSubscriptions() {
        BluetoothManager.shared.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                self?.currentHeartRate = heartRate
                self?.saveHeartRate(heartRate)
            }
            .store(in: &cancellables)

        BluetoothManager.shared.hrvPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hrv in
                self?.latestHRV = hrv
                self?.saveHRV(hrv)
                self?.calculateTodayRecovery()
            }
            .store(in: &cancellables)
    }

    // MARK: - Caching
    private func loadCachedData() {
        // Load cached data from UserDefaults or Core Data
        // This provides immediate data display while fresh data loads
    }
}

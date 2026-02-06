import Foundation
import SwiftUI
import Combine

// MARK: - App State
class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Published Properties
    @Published var isOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded")
        }
    }

    @Published var selectedTab: TabItem = .home

    @Published var userProfile: UserProfile

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var hapticAlarmEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticAlarmEnabled, forKey: "hapticAlarmEnabled")
        }
    }

    @Published var appleHealthSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(appleHealthSyncEnabled, forKey: "appleHealthSyncEnabled")
        }
    }

    // MARK: - Computed Properties
    var calibrationProgress: Int {
        min(30, UserDefaults.standard.integer(forKey: "calibrationDays"))
    }

    var isCalibrated: Bool {
        calibrationProgress >= 30
    }

    // MARK: - Initialization
    private init() {
        self.isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.hapticAlarmEnabled = UserDefaults.standard.bool(forKey: "hapticAlarmEnabled")
        self.appleHealthSyncEnabled = UserDefaults.standard.bool(forKey: "appleHealthSyncEnabled")

        // Load user profile
        self.userProfile = UserProfile.load()
    }

    // MARK: - Methods
    func incrementCalibrationDay() {
        let currentDays = UserDefaults.standard.integer(forKey: "calibrationDays")
        UserDefaults.standard.set(currentDays + 1, forKey: "calibrationDays")
    }

    func resetOnboarding() {
        isOnboarded = false
        UserDefaults.standard.set(0, forKey: "calibrationDays")
    }

    func saveUserProfile() {
        userProfile.save()
    }
}

// MARK: - Tab Item
enum TabItem: String, CaseIterable {
    case home = "Home"
    case sleep = "Sleep"
    case strain = "Strain"
    case coaching = "Coaching"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .sleep: return "moon.fill"
        case .strain: return "flame.fill"
        case .coaching: return "brain.head.profile"
        case .profile: return "person.fill"
        }
    }

    var title: String {
        rawValue
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var name: String
    var email: String
    var dateOfBirth: Date?
    var gender: Gender
    var height: Double // cm
    var weight: Double // kg
    var maxHeartRate: Int
    var restingHeartRate: Int
    var sleepGoal: TimeInterval // seconds
    var strainGoal: Double
    var stepsGoal: Int

    init() {
        self.name = ""
        self.email = ""
        self.dateOfBirth = nil
        self.gender = .preferNotToSay
        self.height = 170
        self.weight = 70
        self.maxHeartRate = 0 // 0 means auto-calculate
        self.restingHeartRate = 60
        self.sleepGoal = 8 * 3600
        self.strainGoal = 14.0
        self.stepsGoal = 10000
    }

    // Calculate max heart rate based on age
    var calculatedMaxHeartRate: Int {
        if maxHeartRate > 0 {
            return maxHeartRate
        }

        guard let dob = dateOfBirth else { return 190 }
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 30
        return 220 - age
    }

    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }
}

// MARK: - Gender
enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}

// MARK: - Notification Types
enum NotificationType: String, CaseIterable {
    case recoveryReady = "Recovery Ready"
    case strainTarget = "Strain Target"
    case sleepReminder = "Sleep Reminder"
    case weeklyReport = "Weekly Report"
    case deviceDisconnected = "Device Disconnected"
    case lowBattery = "Low Battery"

    var icon: String {
        switch self {
        case .recoveryReady: return "heart.fill"
        case .strainTarget: return "flame.fill"
        case .sleepReminder: return "moon.fill"
        case .weeklyReport: return "chart.bar.doc.horizontal"
        case .deviceDisconnected: return "antenna.radiowaves.left.and.right.slash"
        case .lowBattery: return "battery.25"
        }
    }
}

// MARK: - User Preferences
class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    @Published var enabledNotifications: Set<NotificationType> {
        didSet {
            saveNotifications()
        }
    }

    @Published var weeklyReportDay: Int { // 1 = Sunday, 2 = Monday, etc.
        didSet {
            UserDefaults.standard.set(weeklyReportDay, forKey: "weeklyReportDay")
        }
    }

    @Published var sleepReminderTime: Date {
        didSet {
            if let data = try? JSONEncoder().encode(sleepReminderTime) {
                UserDefaults.standard.set(data, forKey: "sleepReminderTime")
            }
        }
    }

    @Published var unitsSystem: UnitsSystem {
        didSet {
            UserDefaults.standard.set(unitsSystem.rawValue, forKey: "unitsSystem")
        }
    }

    private init() {
        // Load enabled notifications
        if let data = UserDefaults.standard.data(forKey: "enabledNotifications"),
           let types = try? JSONDecoder().decode([String].self, from: data) {
            self.enabledNotifications = Set(types.compactMap { NotificationType(rawValue: $0) })
        } else {
            self.enabledNotifications = Set(NotificationType.allCases)
        }

        self.weeklyReportDay = UserDefaults.standard.integer(forKey: "weeklyReportDay")
        if weeklyReportDay == 0 { weeklyReportDay = 2 } // Default Monday

        if let data = UserDefaults.standard.data(forKey: "sleepReminderTime"),
           let time = try? JSONDecoder().decode(Date.self, from: data) {
            self.sleepReminderTime = time
        } else {
            self.sleepReminderTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        }

        self.unitsSystem = UnitsSystem(rawValue: UserDefaults.standard.string(forKey: "unitsSystem") ?? "metric") ?? .metric
    }

    private func saveNotifications() {
        let types = enabledNotifications.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(types) {
            UserDefaults.standard.set(data, forKey: "enabledNotifications")
        }
    }

    func isNotificationEnabled(_ type: NotificationType) -> Bool {
        enabledNotifications.contains(type)
    }

    func toggleNotification(_ type: NotificationType) {
        if enabledNotifications.contains(type) {
            enabledNotifications.remove(type)
        } else {
            enabledNotifications.insert(type)
        }
    }
}

// MARK: - Units System
enum UnitsSystem: String, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"

    var distanceUnit: String {
        switch self {
        case .metric: return "km"
        case .imperial: return "mi"
        }
    }

    var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lb"
        }
    }

    var heightUnit: String {
        switch self {
        case .metric: return "cm"
        case .imperial: return "ft/in"
        }
    }

    func convertDistance(_ meters: Double) -> Double {
        switch self {
        case .metric: return meters / 1000
        case .imperial: return meters / 1609.344
        }
    }

    func convertWeight(_ kg: Double) -> Double {
        switch self {
        case .metric: return kg
        case .imperial: return kg * 2.20462
        }
    }
}

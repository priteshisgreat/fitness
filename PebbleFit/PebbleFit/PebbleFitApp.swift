import SwiftUI
import CoreData
import HealthKit

@main
struct PebbleFitApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var healthManager = HealthManager.shared
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var appState = AppState.shared

    init() {
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(healthManager)
                .environmentObject(bluetoothManager)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }

    private func setupAppearance() {
        // Configure global app appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        UITabBar.appearance().backgroundColor = UIColor(Color.appBackground)
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
}

// MARK: - App State
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded")
        }
    }

    @Published var selectedTab: TabItem = .home
    @Published var showingWorkoutInProgress: Bool = false
    @Published var currentWorkout: Workout?

    private init() {
        self.isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
    }
}

enum TabItem: Int, CaseIterable {
    case home = 0
    case sleep
    case strain
    case coaching
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .sleep: return "Sleep"
        case .strain: return "Strain"
        case .coaching: return "Coaching"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .sleep: return "moon.fill"
        case .strain: return "flame.fill"
        case .coaching: return "brain.head.profile"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Persistence Controller
class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HealthDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}

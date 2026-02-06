import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        Group {
            if !appState.isOnboarded {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.isOnboarded)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(TabItem.home.title, systemImage: TabItem.home.icon)
                }
                .tag(TabItem.home)

            SleepView()
                .tabItem {
                    Label(TabItem.sleep.title, systemImage: TabItem.sleep.icon)
                }
                .tag(TabItem.sleep)

            StrainView()
                .tabItem {
                    Label(TabItem.strain.title, systemImage: TabItem.strain.icon)
                }
                .tag(TabItem.strain)

            CoachingView()
                .tabItem {
                    Label(TabItem.coaching.title, systemImage: TabItem.coaching.icon)
                }
                .tag(TabItem.coaching)

            ProfileView()
                .tabItem {
                    Label(TabItem.profile.title, systemImage: TabItem.profile.icon)
                }
                .tag(TabItem.profile)
        }
        .tint(Color.accentGreen)
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    WelcomeOnboardingPage()
                        .tag(0)

                    FeaturesOnboardingPage()
                        .tag(1)

                    HealthPermissionPage()
                        .tag(2)

                    BluetoothSetupPage()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Navigation Buttons
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(currentPage == 3 ? "Get Started" : "Next") {
                        withAnimation {
                            if currentPage == 3 {
                                appState.isOnboarded = true
                            } else {
                                currentPage += 1
                            }
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.accentGreen)
                    .cornerRadius(25)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
}

struct WelcomeOnboardingPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentGreen, .accentYellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("PebbleFit")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Your Personal Health & Performance Tracker")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
            Spacer()
        }
    }
}

struct FeaturesOnboardingPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Track Everything")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 40)

            VStack(spacing: 25) {
                FeatureRow(icon: "heart.fill", color: .red, title: "Recovery Score", description: "Know when your body is ready to perform")
                FeatureRow(icon: "flame.fill", color: .orange, title: "Strain Tracking", description: "Measure cardiovascular load throughout your day")
                FeatureRow(icon: "moon.fill", color: .purple, title: "Sleep Analysis", description: "Understand your sleep stages and quality")
                FeatureRow(icon: "waveform.path.ecg", color: .accentGreen, title: "HRV Monitoring", description: "Track heart rate variability for insights")
                FeatureRow(icon: "figure.run", color: .blue, title: "Activity Detection", description: "Automatic workout detection and logging")
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}

struct HealthPermissionPage: View {
    @EnvironmentObject var healthManager: HealthManager
    @State private var permissionGranted = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Health Access")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("PebbleFit integrates with Apple Health to provide comprehensive health insights and sync your data.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button(action: requestHealthAccess) {
                HStack {
                    Image(systemName: permissionGranted ? "checkmark.circle.fill" : "heart.fill")
                    Text(permissionGranted ? "Access Granted" : "Grant Health Access")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(permissionGranted ? Color.accentGreen : Color.red)
                .cornerRadius(25)
            }
            .disabled(permissionGranted)

            Spacer()
            Spacer()
        }
    }

    private func requestHealthAccess() {
        healthManager.requestAuthorization { success in
            DispatchQueue.main.async {
                permissionGranted = success
            }
        }
    }
}

struct BluetoothSetupPage: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "applewatch.radiowaves.left.and.right")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Connect Your Pebble Qore 2")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Make sure your Pebble Qore 2 is powered on and nearby.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            if bluetoothManager.isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentGreen)
                    Text("Connected to \(bluetoothManager.connectedDeviceName ?? "Pebble Qore 2")")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
            } else {
                Button(action: startScanning) {
                    HStack {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(isScanning ? "Scanning..." : "Scan for Devices")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                .disabled(isScanning)

                if !bluetoothManager.discoveredDevices.isEmpty {
                    VStack(spacing: 10) {
                        Text("Available Devices")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                            Button(action: { connectToDevice(device) }) {
                                HStack {
                                    Image(systemName: "applewatch")
                                    Text(device.name ?? "Unknown Device")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Text("You can also set this up later in Settings")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
            Spacer()
        }
    }

    private func startScanning() {
        isScanning = true
        bluetoothManager.startScanning()

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            isScanning = false
            bluetoothManager.stopScanning()
        }
    }

    private func connectToDevice(_ device: BluetoothDevice) {
        bluetoothManager.connect(to: device)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(HealthManager.shared)
        .environmentObject(BluetoothManager.shared)
}

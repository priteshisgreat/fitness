import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingEditProfile = false
    @State private var showingDeviceSettings = false
    @State private var showingDataExport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderCard(showingEditProfile: $showingEditProfile)
                        .padding(.horizontal)

                    // Device Connection
                    DeviceConnectionCard(showingDeviceSettings: $showingDeviceSettings)
                        .padding(.horizontal)

                    // Stats Overview
                    StatsOverviewCard()
                        .padding(.horizontal)

                    // Calibration Status
                    CalibrationStatusCard()
                        .padding(.horizontal)

                    // Settings Sections
                    SettingsSectionCard(title: "Goals", items: [
                        SettingItem(icon: "moon.fill", title: "Sleep Goal", value: "8 hours", color: .accentPurple),
                        SettingItem(icon: "flame.fill", title: "Strain Goal", value: "14.0", color: .accentOrange),
                        SettingItem(icon: "figure.walk", title: "Steps Goal", value: "10,000", color: .accentBlue)
                    ])
                    .padding(.horizontal)

                    SettingsSectionCard(title: "Notifications", items: [
                        SettingItem(icon: "bell.fill", title: "Push Notifications", value: "On", color: .accentYellow),
                        SettingItem(icon: "alarm.fill", title: "Haptic Alarm", value: "Enabled", color: .accentPurple),
                        SettingItem(icon: "chart.line.uptrend.xyaxis", title: "Weekly Report", value: "Monday", color: .accentGreen)
                    ])
                    .padding(.horizontal)

                    SettingsSectionCard(title: "Data & Privacy", items: [
                        SettingItem(icon: "heart.fill", title: "Apple Health Sync", value: "On", color: .red),
                        SettingItem(icon: "square.and.arrow.up", title: "Export Data", value: "", color: .accentBlue),
                        SettingItem(icon: "trash.fill", title: "Delete All Data", value: "", color: .accentRed)
                    ])
                    .padding(.horizontal)

                    // App Info
                    AppInfoCard()
                        .padding(.horizontal)

                    // Logout Button
                    Button(action: logout) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.accentRed)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingDeviceSettings) {
                DeviceSettingsView()
            }
        }
    }

    private func logout() {
        appState.isOnboarded = false
    }
}

// MARK: - Profile Header Card
struct ProfileHeaderCard: View {
    @Binding var showingEditProfile: Bool
    @State private var userName = UserDefaults.standard.string(forKey: "userName") ?? "User"

    var body: some View {
        VStack(spacing: 15) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentGreen, .accentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(String(userName.prefix(1)).uppercased())
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(userName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)

                Text("Member since Jan 2024")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Button(action: { showingEditProfile = true }) {
                Text("Edit Profile")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.accentGreen)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentGreen.opacity(0.2))
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Device Connection Card
struct DeviceConnectionCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var showingDeviceSettings: Bool

    var body: some View {
        Button(action: { showingDeviceSettings = true }) {
            HStack {
                // Device icon
                ZStack {
                    Circle()
                        .fill(bluetoothManager.isConnected ? Color.accentGreen.opacity(0.2) : Color.cardBackgroundLight)
                        .frame(width: 50, height: 50)

                    Image(systemName: "applewatch")
                        .font(.title2)
                        .foregroundColor(bluetoothManager.isConnected ? .accentGreen : .gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(bluetoothManager.connectedDeviceName ?? "Pebble Qore 2")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(bluetoothManager.isConnected ? .accentGreen : .gray)
                            .frame(width: 8, height: 8)

                        Text(bluetoothManager.isConnected ? "Connected" : "Not Connected")
                            .font(.caption)
                            .foregroundColor(.gray)

                        if let battery = bluetoothManager.batteryLevel {
                            Text("•")
                                .foregroundColor(.gray)
                            Text("\(battery)%")
                                .font(.caption)
                                .foregroundColor(battery > 20 ? .accentGreen : .accentRed)
                        }
                    }
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

// MARK: - Stats Overview Card
struct StatsOverviewCard: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("All-Time Stats")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                StatItem(value: "127", label: "Days Tracked", icon: "calendar")
                StatItem(value: "89", label: "Workouts", icon: "figure.run")
                StatItem(value: "68%", label: "Avg Recovery", icon: "heart.fill")
            }

            HStack(spacing: 20) {
                StatItem(value: "7.2h", label: "Avg Sleep", icon: "moon.fill")
                StatItem(value: "12.4", label: "Avg Strain", icon: "flame.fill")
                StatItem(value: "52ms", label: "Avg HRV", icon: "waveform.path.ecg")
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentGreen)

            Text(value)
                .font(.headline)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calibration Status Card
struct CalibrationStatusCard: View {
    private var calibrationDays: Int {
        UserDefaults.standard.integer(forKey: "calibrationDays")
    }

    private var isCalibrated: Bool {
        calibrationDays >= 30
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .foregroundColor(isCalibrated ? .accentGreen : .accentYellow)

                Text("Calibration")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(isCalibrated ? "Complete" : "\(calibrationDays)/30 days")
                    .font(.subheadline)
                    .foregroundColor(isCalibrated ? .accentGreen : .accentYellow)
            }

            if !isCalibrated {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cardBackgroundLight)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentYellow)
                            .frame(width: geometry.size.width * CGFloat(calibrationDays) / 30)
                    }
                }
                .frame(height: 8)

                Text("PebbleFit is learning your baseline metrics. Recovery and strain recommendations will improve over the next \(30 - calibrationDays) days.")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("Your personal baselines are calibrated. Recommendations are personalized to your physiology.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Settings Section Card
struct SettingItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let color: Color
}

struct SettingsSectionCard: View {
    let title: String
    let items: [SettingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            ForEach(items) { item in
                HStack {
                    Image(systemName: item.icon)
                        .foregroundColor(item.color)
                        .frame(width: 24)

                    Text(item.title)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Spacer()

                    if !item.value.isEmpty {
                        Text(item.value)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - App Info Card
struct AppInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("About")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Text("Version")
                    .foregroundColor(.gray)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.white)
            }
            .font(.subheadline)

            HStack {
                Text("Build")
                    .foregroundColor(.gray)
                Spacer()
                Text("2024.1")
                    .foregroundColor(.white)
            }
            .font(.subheadline)

            Divider()
                .background(Color.cardBackgroundLight)

            NavigationLink(destination: PrivacyPolicyView()) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }

            NavigationLink(destination: TermsOfServiceView()) {
                HStack {
                    Text("Terms of Service")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }

            Link(destination: URL(string: "https://pebblefit.app/support")!) {
                HStack {
                    Text("Help & Support")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.gray)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    @State private var dateOfBirth = UserDefaults.standard.object(forKey: "userDOB") as? Date ?? Date()
    @State private var selectedGender = Gender.preferNotToSay
    @State private var height = UserDefaults.standard.double(forKey: "userHeight")
    @State private var weight = UserDefaults.standard.double(forKey: "userWeight")
    @State private var maxHeartRate = UserDefaults.standard.integer(forKey: "maxHeartRate")

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }

                Section("Body Metrics") {
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", value: $height, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.gray)
                    }
                }

                Section("Heart Rate Settings") {
                    HStack {
                        Text("Max Heart Rate")
                        Spacer()
                        TextField("BPM", value: $maxHeartRate, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("BPM")
                            .foregroundColor(.gray)
                    }

                    Text("Leave at 0 to auto-calculate based on age (220 - age)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveProfile() {
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(dateOfBirth, forKey: "userDOB")
        UserDefaults.standard.set(selectedGender.rawValue, forKey: "userGender")
        UserDefaults.standard.set(height, forKey: "userHeight")
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(maxHeartRate, forKey: "maxHeartRate")
    }
}

// MARK: - Device Settings View
struct DeviceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Device
                    if bluetoothManager.isConnected {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Connected Device")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                Image(systemName: "applewatch")
                                    .font(.largeTitle)
                                    .foregroundColor(.accentGreen)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bluetoothManager.connectedDeviceName ?? "Pebble Qore 2")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    if let battery = bluetoothManager.batteryLevel {
                                        Text("Battery: \(battery)%")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }

                                Spacer()

                                Button("Disconnect") {
                                    bluetoothManager.disconnect()
                                }
                                .foregroundColor(.accentRed)
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                    }

                    // Scan for Devices
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Available Devices")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: toggleScanning) {
                                HStack {
                                    if isScanning {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isScanning ? "Scanning..." : "Scan")
                                }
                                .font(.subheadline)
                                .foregroundColor(.accentGreen)
                            }
                        }

                        if bluetoothManager.discoveredDevices.isEmpty && !isScanning {
                            Text("No devices found. Make sure your Pebble Qore 2 is powered on and nearby.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(bluetoothManager.discoveredDevices) { device in
                                Button(action: { connectToDevice(device) }) {
                                    HStack {
                                        Image(systemName: "applewatch.radiowaves.left.and.right")
                                            .foregroundColor(.accentBlue)

                                        VStack(alignment: .leading) {
                                            Text(device.name ?? "Unknown Device")
                                                .foregroundColor(.white)
                                            Text("Signal: \(device.rssi) dBm")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)

                    // Device Info
                    if bluetoothManager.isConnected {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Device Information")
                                .font(.headline)
                                .foregroundColor(.white)

                            InfoRow(label: "Model", value: "Pebble Qore 2")
                            InfoRow(label: "Firmware", value: "v2.1.3")
                            InfoRow(label: "Hardware", value: "Rev C")
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Device Settings")
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

    private func toggleScanning() {
        if isScanning {
            bluetoothManager.stopScanning()
            isScanning = false
        } else {
            bluetoothManager.startScanning()
            isScanning = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                isScanning = false
                bluetoothManager.stopScanning()
            }
        }
    }

    private func connectToDevice(_ device: BluetoothDevice) {
        bluetoothManager.connect(to: device)
        isScanning = false
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.subheadline)
    }
}

// MARK: - Placeholder Views
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content goes here...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content goes here...")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState.shared)
        .environmentObject(HealthManager.shared)
        .environmentObject(BluetoothManager.shared)
}

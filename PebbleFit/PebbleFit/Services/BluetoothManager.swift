import Foundation
import CoreBluetooth
import Combine

// MARK: - Bluetooth Device
struct BluetoothDevice: Identifiable {
    let id: UUID
    let identifier: UUID
    let name: String?
    let rssi: Int
    let peripheral: CBPeripheral

    init(peripheral: CBPeripheral, rssi: Int) {
        self.id = peripheral.identifier
        self.identifier = peripheral.identifier
        self.name = peripheral.name
        self.rssi = rssi
        self.peripheral = peripheral
    }
}

// MARK: - Pebble Service UUIDs
enum PebbleServiceUUID {
    // Generic UUIDs for fitness devices
    static let heartRateService = CBUUID(string: "180D")
    static let heartRateMeasurement = CBUUID(string: "2A37")
    static let bodySensorLocation = CBUUID(string: "2A38")

    static let deviceInfoService = CBUUID(string: "180A")
    static let manufacturerName = CBUUID(string: "2A29")
    static let modelNumber = CBUUID(string: "2A24")
    static let firmwareRevision = CBUUID(string: "2A26")

    static let batteryService = CBUUID(string: "180F")
    static let batteryLevel = CBUUID(string: "2A19")

    // Pebble Qore 2 specific UUIDs (hypothetical - adjust based on actual device specs)
    static let pebbleService = CBUUID(string: "FED0")
    static let pebbleDataCharacteristic = CBUUID(string: "FED1")
    static let pebbleControlCharacteristic = CBUUID(string: "FED2")
    static let pebbleHRVCharacteristic = CBUUID(string: "FED3")
    static let pebbleSleepCharacteristic = CBUUID(string: "FED4")
    static let pebbleActivityCharacteristic = CBUUID(string: "FED5")

    static var allServices: [CBUUID] {
        [heartRateService, deviceInfoService, batteryService, pebbleService]
    }
}

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()

    // MARK: - Published Properties
    @Published var isBluetoothEnabled = false
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var connectedDeviceName: String?
    @Published var batteryLevel: Int?
    @Published var currentHeartRate: Double = 0
    @Published var latestHRV: Double = 0
    @Published var connectionError: String?

    // MARK: - Real-time Data Publishers
    let heartRatePublisher = PassthroughSubject<Double, Never>()
    let hrvPublisher = PassthroughSubject<Double, Never>()
    let activityPublisher = PassthroughSubject<ActivityData, Never>()
    let sleepDataPublisher = PassthroughSubject<SleepData, Never>()

    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var heartRateCharacteristic: CBCharacteristic?
    private var hrvCharacteristic: CBCharacteristic?
    private var activityCharacteristic: CBCharacteristic?
    private var sleepCharacteristic: CBCharacteristic?
    private var batteryCharacteristic: CBCharacteristic?

    private var reconnectTimer: Timer?
    private var lastConnectedDeviceIdentifier: UUID?

    // MARK: - Initialization
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        // Load last connected device
        if let uuidString = UserDefaults.standard.string(forKey: "lastConnectedDeviceUUID"),
           let uuid = UUID(uuidString: uuidString) {
            lastConnectedDeviceIdentifier = uuid
        }
    }

    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionError = "Bluetooth is not available"
            return
        }

        isScanning = true
        discoveredDevices.removeAll()

        centralManager.scanForPeripherals(
            withServices: nil, // Scan for all devices initially
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        // Stop scanning after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.stopScanning()
        }
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }

    func connect(to device: BluetoothDevice) {
        stopScanning()
        isConnecting = true
        connectionError = nil

        centralManager.connect(device.peripheral, options: nil)

        // Save device identifier for auto-reconnect
        lastConnectedDeviceIdentifier = device.identifier
        UserDefaults.standard.set(device.identifier.uuidString, forKey: "lastConnectedDeviceUUID")
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func attemptAutoReconnect() {
        guard let identifier = lastConnectedDeviceIdentifier else { return }

        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [identifier])
        if let peripheral = knownPeripherals.first {
            isConnecting = true
            centralManager.connect(peripheral, options: nil)
        }
    }

    // MARK: - Data Request Methods
    func requestCurrentHeartRate() {
        guard let characteristic = heartRateCharacteristic else { return }
        connectedPeripheral?.readValue(for: characteristic)
    }

    func requestHRV() {
        guard let characteristic = hrvCharacteristic else { return }
        connectedPeripheral?.readValue(for: characteristic)
    }

    func requestSleepData() {
        guard let characteristic = sleepCharacteristic else { return }
        connectedPeripheral?.readValue(for: characteristic)
    }

    func requestActivityData() {
        guard let characteristic = activityCharacteristic else { return }
        connectedPeripheral?.readValue(for: characteristic)
    }

    func requestBatteryLevel() {
        guard let characteristic = batteryCharacteristic else { return }
        connectedPeripheral?.readValue(for: characteristic)
    }

    // MARK: - Private Methods
    private func discoverServices() {
        connectedPeripheral?.discoverServices(PebbleServiceUUID.allServices)
    }

    private func setupNotifications() {
        // Enable notifications for heart rate
        if let hrCharacteristic = heartRateCharacteristic {
            connectedPeripheral?.setNotifyValue(true, for: hrCharacteristic)
        }

        // Enable notifications for HRV
        if let hrvChar = hrvCharacteristic {
            connectedPeripheral?.setNotifyValue(true, for: hrvChar)
        }

        // Enable notifications for activity
        if let activityChar = activityCharacteristic {
            connectedPeripheral?.setNotifyValue(true, for: activityChar)
        }
    }

    private func parseHeartRateData(_ data: Data) -> Double {
        // Heart Rate Measurement characteristic format
        let bytes = [UInt8](data)
        guard !bytes.isEmpty else { return 0 }

        let flags = bytes[0]
        let is16Bit = (flags & 0x01) != 0

        if is16Bit && bytes.count >= 3 {
            return Double(UInt16(bytes[1]) | (UInt16(bytes[2]) << 8))
        } else if bytes.count >= 2 {
            return Double(bytes[1])
        }

        return 0
    }

    private func parseHRVData(_ data: Data) -> Double {
        // Parse RR intervals and calculate RMSSD
        let bytes = [UInt8](data)
        var rrIntervals: [Double] = []

        // Assuming RR intervals are 16-bit values in milliseconds
        var index = 0
        while index + 1 < bytes.count {
            let rr = Double(UInt16(bytes[index]) | (UInt16(bytes[index + 1]) << 8))
            rrIntervals.append(rr)
            index += 2
        }

        // Calculate RMSSD (Root Mean Square of Successive Differences)
        guard rrIntervals.count >= 2 else { return 0 }

        var sumSquaredDiffs: Double = 0
        for i in 1..<rrIntervals.count {
            let diff = rrIntervals[i] - rrIntervals[i - 1]
            sumSquaredDiffs += diff * diff
        }

        let rmssd = sqrt(sumSquaredDiffs / Double(rrIntervals.count - 1))
        return rmssd
    }

    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.attemptAutoReconnect()
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.isBluetoothEnabled = central.state == .poweredOn

            if central.state == .poweredOn {
                // Attempt to reconnect to last device
                self.attemptAutoReconnect()
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Filter for Pebble devices or any fitness device
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String

        // Accept devices that might be Pebble Qore 2 or generic heart rate monitors
        let isPebbleDevice = deviceName?.lowercased().contains("pebble") ?? false
        let isHeartRateDevice = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .contains(PebbleServiceUUID.heartRateService) ?? false

        if isPebbleDevice || isHeartRateDevice || deviceName != nil {
            let device = BluetoothDevice(peripheral: peripheral, rssi: RSSI.intValue)

            DispatchQueue.main.async {
                if !self.discoveredDevices.contains(where: { $0.identifier == device.identifier }) {
                    self.discoveredDevices.append(device)
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.isConnecting = false
            self.connectedPeripheral = peripheral
            self.connectedDeviceName = peripheral.name ?? "Pebble Qore 2"
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = nil
        }

        peripheral.delegate = self
        peripheral.discoverServices(PebbleServiceUUID.allServices)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnecting = false
            self.connectionError = error?.localizedDescription ?? "Failed to connect"
        }

        scheduleReconnect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeripheral = nil
            self.connectedDeviceName = nil
            self.heartRateCharacteristic = nil
            self.hrvCharacteristic = nil
            self.activityCharacteristic = nil
            self.sleepCharacteristic = nil
            self.batteryCharacteristic = nil
        }

        // Attempt to reconnect
        scheduleReconnect()
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case PebbleServiceUUID.heartRateMeasurement:
                heartRateCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)

            case PebbleServiceUUID.pebbleHRVCharacteristic:
                hrvCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)

            case PebbleServiceUUID.pebbleActivityCharacteristic:
                activityCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)

            case PebbleServiceUUID.pebbleSleepCharacteristic:
                sleepCharacteristic = characteristic

            case PebbleServiceUUID.batteryLevel:
                batteryCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }

        DispatchQueue.main.async {
            switch characteristic.uuid {
            case PebbleServiceUUID.heartRateMeasurement:
                let heartRate = self.parseHeartRateData(data)
                self.currentHeartRate = heartRate
                self.heartRatePublisher.send(heartRate)

            case PebbleServiceUUID.pebbleHRVCharacteristic:
                let hrv = self.parseHRVData(data)
                self.latestHRV = hrv
                self.hrvPublisher.send(hrv)

            case PebbleServiceUUID.batteryLevel:
                if let firstByte = data.first {
                    self.batteryLevel = Int(firstByte)
                }

            default:
                break
            }
        }
    }
}

// MARK: - Activity Data
struct ActivityData {
    let steps: Int
    let calories: Double
    let distance: Double
    let activeMinutes: Int
    let timestamp: Date
}

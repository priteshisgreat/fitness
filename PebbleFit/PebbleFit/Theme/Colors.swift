import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let appBackground = Color(hex: "0D0D0D")
    static let cardBackground = Color(hex: "1A1A1A")
    static let cardBackgroundLight = Color(hex: "2A2A2A")
    static let surfaceBackground = Color(hex: "141414")

    // MARK: - Accent Colors
    static let accentGreen = Color(hex: "00F5A0")
    static let accentYellow = Color(hex: "FFD60A")
    static let accentRed = Color(hex: "FF453A")
    static let accentBlue = Color(hex: "0A84FF")
    static let accentPurple = Color(hex: "BF5AF2")
    static let accentOrange = Color(hex: "FF9F0A")
    static let accentCyan = Color(hex: "64D2FF")
    static let accentPink = Color(hex: "FF375F")

    // MARK: - Recovery Colors
    static let recoveryGreen = Color(hex: "00F5A0")
    static let recoveryYellow = Color(hex: "FFD60A")
    static let recoveryRed = Color(hex: "FF453A")

    // MARK: - Sleep Stage Colors
    static let sleepAwake = Color(hex: "FF453A")
    static let sleepLight = Color(hex: "5E5CE6")
    static let sleepDeep = Color(hex: "BF5AF2")
    static let sleepREM = Color(hex: "64D2FF")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "636366")

    // MARK: - Chart Colors
    static let chartLine = Color(hex: "00F5A0")
    static let chartFill = Color(hex: "00F5A0").opacity(0.3)
    static let chartGrid = Color(hex: "2C2C2E")

    // MARK: - Gradient Presets
    static let recoveryGradient = LinearGradient(
        colors: [accentGreen, accentGreen.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let strainGradient = LinearGradient(
        colors: [accentOrange, accentRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sleepGradient = LinearGradient(
        colors: [accentPurple, accentBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackgroundLight],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Heart Rate Zone Colors
    static func heartRateZoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return Color(hex: "8E8E93")
        case 2: return Color(hex: "0A84FF")
        case 3: return Color(hex: "00F5A0")
        case 4: return Color(hex: "FF9F0A")
        case 5: return Color(hex: "FF453A")
        default: return Color(hex: "8E8E93")
        }
    }

    // MARK: - Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct GlassStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(16)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func glassStyle() -> some View {
        modifier(GlassStyle())
    }
}

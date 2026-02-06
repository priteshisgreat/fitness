import SwiftUI

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient
    var showLabel: Bool = true
    var labelText: String?
    var sublabelText: String?

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.cardBackgroundLight, lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Label
            if showLabel {
                VStack(spacing: 4) {
                    Text(labelText ?? "\(Int(progress * 100))%")
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(.white)

                    if let sublabel = sublabelText {
                        Text(sublabel)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Score Ring View
struct ScoreRingView: View {
    let score: Double
    let maxScore: Double
    let category: RecoveryCategory?
    let title: String
    let icon: String
    let size: CGFloat

    private var progress: Double {
        score / maxScore
    }

    private var ringColor: Color {
        category?.color ?? .accentGreen
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.cardBackgroundLight, lineWidth: size * 0.08)
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: 2) {
                    if maxScore == 21 {
                        Text(String(format: "%.1f", score))
                            .font(.system(size: size * 0.25, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(Int(score))")
                            .font(.system(size: size * 0.3, weight: .bold))
                            .foregroundColor(.white)

                        if maxScore == 100 {
                            Text("%")
                                .font(.system(size: size * 0.12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(ringColor)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Mini Score View
struct MiniScoreView: View {
    let value: Double
    let maxValue: Double
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.cardBackgroundLight, lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: value / maxValue)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(value))")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Strain Gauge View
struct StrainGaugeView: View {
    let currentStrain: Double
    let targetMin: Double
    let targetMax: Double
    let size: CGFloat

    private var strainProgress: Double {
        currentStrain / 21.0
    }

    private var strainColor: Color {
        if currentStrain < 9 { return .accentBlue }
        if currentStrain < 14 { return .accentGreen }
        if currentStrain < 18 { return .accentOrange }
        return .accentRed
    }

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(Color.cardBackgroundLight, lineWidth: size * 0.1)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(90))

            // Target zone arc
            Circle()
                .trim(from: 0.15 + (targetMin / 21.0 * 0.7), to: 0.15 + (targetMax / 21.0 * 0.7))
                .stroke(Color.accentGreen.opacity(0.3), lineWidth: size * 0.1)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(90))

            // Current strain arc
            Circle()
                .trim(from: 0.15, to: 0.15 + (strainProgress * 0.7))
                .stroke(
                    strainColor,
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(90))
                .animation(.easeInOut(duration: 0.5), value: strainProgress)

            VStack(spacing: 4) {
                Text(String(format: "%.1f", currentStrain))
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(.white)

                Text("Strain")
                    .font(.system(size: size * 0.1))
                    .foregroundColor(.gray)
            }

            // Scale markers
            ForEach([0, 7, 14, 21], id: \.self) { value in
                ScaleMarker(value: value, size: size)
            }
        }
    }
}

struct ScaleMarker: View {
    let value: Int
    let size: CGFloat

    private var angle: Double {
        let progress = Double(value) / 21.0
        return -135 + (progress * 270)
    }

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.system(size: size * 0.08))
                .foregroundColor(.gray)
        }
        .offset(y: -size * 0.35)
        .rotationEffect(.degrees(angle))
    }
}

// MARK: - Heart Rate Zone Bar
struct HeartRateZoneBar: View {
    let currentZone: Int
    let heartRate: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { zone in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(zone <= currentZone ? zoneColor(zone) : Color.cardBackgroundLight)
                        .frame(height: 8)
                }
            }

            HStack {
                Text("Zone \(currentZone)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(zoneColor(currentZone))

                Spacer()

                Text("\(Int(heartRate)) BPM")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return .blue
        case 2: return .accentGreen
        case 3: return .accentYellow
        case 4: return .accentOrange
        case 5: return .accentRed
        default: return .gray
        }
    }
}

// MARK: - Sleep Stage Bar
struct SleepStageBar: View {
    let stages: [SleepStage]
    let totalDuration: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(stages) { stage in
                    Rectangle()
                        .fill(stage.stage.color)
                        .frame(width: CGFloat(stage.duration / totalDuration) * geometry.size.width)
                }
            }
            .cornerRadius(4)
        }
    }
}

// MARK: - Animated Pulse View
struct PulseView: View {
    @State private var animate = false

    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 60, height: 60)
                .scaleEffect(animate ? 1.2 : 1)

            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 40, height: 40)
                .scaleEffect(animate ? 1.1 : 1)

            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Loading Indicator
struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.accentGreen, lineWidth: 3)
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

            Text("Loading...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        ScoreRingView(
            score: 72,
            maxScore: 100,
            category: .green,
            title: "Recovery",
            icon: "heart.fill",
            size: 120
        )

        StrainGaugeView(
            currentStrain: 12.5,
            targetMin: 10,
            targetMax: 16,
            size: 150
        )

        HeartRateZoneBar(currentZone: 3, heartRate: 145)
            .padding(.horizontal)

        PulseView(color: .accentGreen)
    }
    .padding()
    .background(Color.appBackground)
}

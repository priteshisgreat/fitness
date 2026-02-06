import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var healthManager: HealthManager
    @State private var selectedMetric: TrendMetric = .recovery
    @State private var selectedTimeRange: TimeRange = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Metric Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TrendMetric.allCases, id: \.self) { metric in
                                MetricChip(
                                    metric: metric,
                                    isSelected: selectedMetric == metric,
                                    action: { selectedMetric = metric }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Time Range Selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Main Chart
                    TrendChartCard(metric: selectedMetric, timeRange: selectedTimeRange)
                        .padding(.horizontal)

                    // Statistics Summary
                    StatisticsSummaryCard(metric: selectedMetric, timeRange: selectedTimeRange)
                        .padding(.horizontal)

                    // Comparison Card
                    ComparisonCard(metric: selectedMetric, timeRange: selectedTimeRange)
                        .padding(.horizontal)

                    // Weekly Performance Assessment
                    WeeklyPerformanceCard()
                        .padding(.horizontal)

                    // Monthly Trends
                    MonthlyTrendsCard()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Trends")
        }
    }
}

// MARK: - Enums
enum TrendMetric: String, CaseIterable {
    case recovery = "Recovery"
    case strain = "Strain"
    case sleep = "Sleep"
    case hrv = "HRV"
    case restingHR = "Resting HR"

    var icon: String {
        switch self {
        case .recovery: return "heart.fill"
        case .strain: return "flame.fill"
        case .sleep: return "moon.fill"
        case .hrv: return "waveform.path.ecg"
        case .restingHR: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .recovery: return .accentGreen
        case .strain: return .accentOrange
        case .sleep: return .accentPurple
        case .hrv: return .accentBlue
        case .restingHR: return .red
        }
    }

    var unit: String {
        switch self {
        case .recovery: return "%"
        case .strain: return ""
        case .sleep: return "hrs"
        case .hrv: return "ms"
        case .restingHR: return "BPM"
        }
    }
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
}

// MARK: - Metric Chip
struct MetricChip: View {
    let metric: TrendMetric
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                Text(metric.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? metric.color : Color.cardBackground)
            .cornerRadius(20)
        }
    }
}

// MARK: - Trend Chart Card
struct TrendChartCard: View {
    let metric: TrendMetric
    let timeRange: TimeRange
    @EnvironmentObject var healthManager: HealthManager

    private var chartData: [ChartDataPoint] {
        generateChartData()
    }

    private var average: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.value }.reduce(0, +) / Double(chartData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average \(metric.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formatValue(average))
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text(metric.unit)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                TrendIndicator(currentAverage: average, previousAverage: average * 0.95)
            }

            // Chart
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(chartData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(metric.rawValue, point.value)
                        )
                        .foregroundStyle(metric.color)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value(metric.rawValue, point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [metric.color.opacity(0.3), metric.color.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    // Average line
                    RuleMark(y: .value("Average", average))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.gray)
                    }
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS 15
                LegacyChartView(data: chartData, color: metric.color)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func generateChartData() -> [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        let calendar = Calendar.current

        for i in 0..<timeRange.days {
            let date = calendar.date(byAdding: .day, value: -timeRange.days + i + 1, to: Date())!

            let value: Double
            switch metric {
            case .recovery:
                value = Double.random(in: 40...90)
            case .strain:
                value = Double.random(in: 5...18)
            case .sleep:
                value = Double.random(in: 5...9)
            case .hrv:
                value = Double.random(in: 30...80)
            case .restingHR:
                value = Double.random(in: 50...70)
            }

            data.append(ChartDataPoint(date: date, value: value))
        }

        return data
    }

    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .recovery, .restingHR:
            return String(format: "%.0f", value)
        case .strain:
            return String(format: "%.1f", value)
        case .sleep:
            return String(format: "%.1f", value)
        case .hrv:
            return String(format: "%.0f", value)
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Legacy Chart View (iOS 15 fallback)
struct LegacyChartView: View {
    let data: [ChartDataPoint]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.map { $0.value }.max() ?? 1
            let minValue = data.map { $0.value }.min() ?? 0
            let range = maxValue - minValue

            Path { path in
                guard !data.isEmpty else { return }

                let stepX = geometry.size.width / CGFloat(data.count - 1)

                for (index, point) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = range > 0 ? (point.value - minValue) / range : 0.5
                    let y = geometry.size.height * (1 - CGFloat(normalizedY))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
        }
    }
}

// MARK: - Trend Indicator
struct TrendIndicator: View {
    let currentAverage: Double
    let previousAverage: Double

    private var percentChange: Double {
        guard previousAverage > 0 else { return 0 }
        return ((currentAverage - previousAverage) / previousAverage) * 100
    }

    private var isPositive: Bool {
        percentChange >= 0
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)

            Text("\(abs(percentChange), specifier: "%.1f")%")
                .font(.subheadline.weight(.medium))
        }
        .foregroundColor(isPositive ? .accentGreen : .accentRed)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((isPositive ? Color.accentGreen : Color.accentRed).opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Statistics Summary Card
struct StatisticsSummaryCard: View {
    let metric: TrendMetric
    let timeRange: TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                StatBox(label: "High", value: getHighValue(), color: .accentGreen)
                StatBox(label: "Average", value: getAverageValue(), color: metric.color)
                StatBox(label: "Low", value: getLowValue(), color: .accentRed)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func getHighValue() -> String {
        switch metric {
        case .recovery: return "92%"
        case .strain: return "18.2"
        case .sleep: return "8.5 hrs"
        case .hrv: return "78 ms"
        case .restingHR: return "52 BPM"
        }
    }

    private func getAverageValue() -> String {
        switch metric {
        case .recovery: return "68%"
        case .strain: return "12.4"
        case .sleep: return "7.2 hrs"
        case .hrv: return "52 ms"
        case .restingHR: return "58 BPM"
        }
    }

    private func getLowValue() -> String {
        switch metric {
        case .recovery: return "42%"
        case .strain: return "4.8"
        case .sleep: return "5.1 hrs"
        case .hrv: return "28 ms"
        case .restingHR: return "65 BPM"
        }
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Comparison Card
struct ComparisonCard: View {
    let metric: TrendMetric
    let timeRange: TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Period Comparison")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                ComparisonColumn(
                    title: "This \(timeRange.rawValue)",
                    value: getCurrentValue(),
                    isHighlighted: true,
                    color: metric.color
                )

                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)

                ComparisonColumn(
                    title: "Last \(timeRange.rawValue)",
                    value: getPreviousValue(),
                    isHighlighted: false,
                    color: .gray
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func getCurrentValue() -> String {
        switch metric {
        case .recovery: return "68%"
        case .strain: return "12.4"
        case .sleep: return "7.2 hrs"
        case .hrv: return "52 ms"
        case .restingHR: return "58 BPM"
        }
    }

    private func getPreviousValue() -> String {
        switch metric {
        case .recovery: return "65%"
        case .strain: return "11.8"
        case .sleep: return "6.9 hrs"
        case .hrv: return "48 ms"
        case .restingHR: return "61 BPM"
        }
    }
}

struct ComparisonColumn: View {
    let title: String
    let value: String
    let isHighlighted: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(isHighlighted ? .white : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isHighlighted ? color.opacity(0.15) : Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Performance Card
struct WeeklyPerformanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.accentBlue)
                Text("Weekly Performance Assessment")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Performance summary
            HStack(spacing: 15) {
                WPAMetric(label: "Training Balance", status: "Optimal", color: .accentGreen)
                WPAMetric(label: "Sleep Trend", status: "Improving", color: .accentGreen)
                WPAMetric(label: "Recovery Trend", status: "Stable", color: .accentYellow)
            }

            Text("Your training load is well-balanced. Continue maintaining this pattern for optimal performance gains.")
                .font(.caption)
                .foregroundColor(.gray)

            NavigationLink(destination: WPADetailView()) {
                HStack {
                    Text("View Full Report")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.accentGreen)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct WPAMetric: View {
    let label: String
    let status: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(status)
                .font(.caption.weight(.medium))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Monthly Trends Card
struct MonthlyTrendsCard: View {
    let months = ["Oct", "Nov", "Dec", "Jan"]
    let recoveryData = [65.0, 68.0, 72.0, 70.0]
    let strainData = [11.2, 12.5, 13.1, 12.8]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentPurple)
                Text("Monthly Overview")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<months.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        // Recovery bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentGreen)
                            .frame(width: 20, height: CGFloat(recoveryData[index]))

                        // Strain bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentOrange)
                            .frame(width: 20, height: CGFloat(strainData[index] * 4))

                        Text(months[index])
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.accentGreen)
                            .frame(width: 8, height: 8)
                        Text("Recovery")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.accentOrange)
                            .frame(width: 8, height: 8)
                        Text("Strain")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - WPA Detail View
struct WPADetailView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Training Balance
                VStack(alignment: .leading, spacing: 15) {
                    Text("Training Balance")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        TrainingBalanceBar(label: "Restoring", percentage: 15, color: .accentBlue)
                        TrainingBalanceBar(label: "Optimal", percentage: 60, color: .accentGreen)
                        TrainingBalanceBar(label: "Overreaching", percentage: 25, color: .accentRed)
                    }

                    Text("60% of your days were in the optimal training zone. This is excellent for building fitness while maintaining recovery.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)

                // Sleep Analysis
                VStack(alignment: .leading, spacing: 15) {
                    Text("Sleep Analysis")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg Sleep")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("7h 12m")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("vs 3-week avg")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("+18 min")
                                .font(.title2.bold())
                                .foregroundColor(.accentGreen)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)

                // Recommendations
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recommendations")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 12) {
                        RecommendationRow(
                            icon: "checkmark.circle.fill",
                            text: "Continue your current training pattern",
                            color: .accentGreen
                        )
                        RecommendationRow(
                            icon: "moon.fill",
                            text: "Aim for more consistent bedtimes",
                            color: .accentPurple
                        )
                        RecommendationRow(
                            icon: "drop.fill",
                            text: "Increase hydration on high strain days",
                            color: .accentBlue
                        )
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Weekly Report")
    }
}

struct TrainingBalanceBar: View {
    let label: String
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(height: CGFloat(percentage))

            Text("\(percentage)%")
                .font(.caption.weight(.medium))
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    TrendsView()
        .environmentObject(HealthManager.shared)
}

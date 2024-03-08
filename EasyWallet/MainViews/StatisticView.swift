import SwiftUI
import SwiftUICharts
import CoreData

struct StatisticView: View {
    @State private var monthlyExpenses: Double = 0.0
    @State private var yearlyExpenses: Double = 0.0
    @State private var nextDueSubscriptions: [Subscription] = []
    @State private var pinnedUnpinnedRatio: (pinned: Int, unpinned: Int) = (0, 0)


    @FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Subscription.isPinned, ascending: false),
                NSSortDescriptor(keyPath: \Subscription.isPaused, ascending: true),
                NSSortDescriptor(keyPath: \Subscription.timestamp, ascending: true)
            ],
            animation: .default)
    private var fetchedSubscriptions: FetchedResults<Subscription>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Section {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                    .foregroundColor(.blue)
                                    .padding(.trailing, 5)
                            Text(String(localized: "Subscriptions"))
                                    .font(.title)
                                    .fontWeight(.semibold)
                            Spacer()
                            Text("\(fetchedSubscriptions.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                        }
                                .padding()
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .padding(.horizontal)
                        if let data = makeYearlyToMonthlyData() {
                            PieChart(chartData: data)
                                    .touchOverlay(chartData: data)
                                    .headerBox(chartData: data)
                                    .legends(chartData: data, columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())])
                                    .frame(minWidth: 50, maxWidth: 500, minHeight: 50, idealHeight: 250, maxHeight: 300, alignment: .center)
                                    .id(data.id)
                                    .padding(.horizontal)
                        }
                    }
                            .padding()

                    HStack {
                        if let data = makePinnedData() {
                            PieChart(chartData: data)
                                    .touchOverlay(chartData: data)
                                    .headerBox(chartData: data)
                                    .frame(minWidth: 50, maxWidth: 450, minHeight: 50, idealHeight: 250, maxHeight: 300, alignment: .center)
                                    .id(data.id)
                                    .padding(.horizontal)
                        }
                        if let data = makePausedData() {
                            PieChart(chartData: data)
                                    .touchOverlay(chartData: data)
                                    .headerBox(chartData: data)
                                    .frame(minWidth: 50, maxWidth: 450, minHeight: 50, idealHeight: 250, maxHeight: 300, alignment: .center)
                                    .id(data.id)
                                    .padding(.horizontal)
                        }
                    }
                }
            }
                    .navigationTitle(String(localized: "Statistics"))
        }
    }

    func calculateYearlyToMonthlyDataPoints(from subscriptions: [Subscription]) -> [PieChartDataPoint] {
        let patterns = subscriptions.map {
            $0.repeatPattern
        }
        let counts = patterns.reduce(into: [:]) { counts, pattern in
            counts[pattern, default: 0] += 1
        }
        let chartDataPoints = counts.map { pattern, count -> PieChartDataPoint in
            switch pattern {
            case ContentView.PayRate.monthly.rawValue:
                return PieChartDataPoint(value: Double(count), description: String(localized: "\(pattern ?? "Unknown")"), colour: .blue, label: .icon(systemName: "\(count).square", colour: .white, size: 30))
            case ContentView.PayRate.yearly.rawValue:
                return PieChartDataPoint(value: Double(count), description: pattern, colour: .red, label: .icon(systemName: "\(count).square", colour: .white, size: 30))
            default:
                return PieChartDataPoint(value: Double(count), description: String(localized: "Unknown"), colour: .gray, label: .icon(systemName: "\(count).circle", colour: .white, size: 30))
            }
        }
        return chartDataPoints
    }

    func makeYearlyToMonthlyData() -> PieChartData? {
        let dataPoints = calculateYearlyToMonthlyDataPoints(from: Array(fetchedSubscriptions))
        guard !dataPoints.isEmpty else {
            return nil
        }
        let dataSet = PieDataSet(dataPoints: dataPoints, legendTitle: String(localized: "Monthly to Yearly"))
        return PieChartData(dataSets: dataSet, metadata: ChartMetadata(title: String(localized: "Monthly to Yearly"), subtitle: ""), chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    func makePinnedData() -> PieChartData? {
        let dataPoints = calculatePinnedToPausedDataPoints(pinned: true, subscriptions: Array(fetchedSubscriptions))
        guard !dataPoints.isEmpty else {
            return nil
        }
        let dataSet = PieDataSet(dataPoints: dataPoints, legendTitle: String(localized: "Pinned"))
        return PieChartData(dataSets: dataSet, metadata: ChartMetadata(title: String(localized: "Pinned"), subtitle: ""), chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }

    func makePausedData() -> PieChartData? {
        let dataPoints = calculatePinnedToPausedDataPoints(pinned: false, subscriptions: Array(fetchedSubscriptions))
        guard !dataPoints.isEmpty else {
            return nil
        }
        let dataSet = PieDataSet(dataPoints: dataPoints, legendTitle: String(localized: "Paused"))
        return PieChartData(dataSets: dataSet, metadata: ChartMetadata(title: String(localized: "Paused"), subtitle: ""), chartStyle: PieChartStyle(infoBoxPlacement: .header))
    }


    func calculatePinnedToPausedDataPoints(pinned: Bool, subscriptions: [Subscription]) -> [PieChartDataPoint] {
        var data = subscriptions.filter {
                    $0.isPaused == true
                }
                .count
        var normalData = subscriptions.filter {
                    $0.isPaused == false
                }
                .count
        if (pinned) {
            data = subscriptions.filter {
                        $0.isPinned == true
                    }
                    .count
            normalData = subscriptions.filter {
                        !$0.isPinned
                    }
                    .count
        }
        let chartDataPoints: [PieChartDataPoint] = [
            PieChartDataPoint(value: Double(normalData), description: "Normal", colour: .blue, label: .icon(systemName: "\(normalData).square", colour: .white, size: 25)),
            PieChartDataPoint(value: Double(data), description: "Paused", colour: .red, label: .icon(systemName: "\(data).square", colour: .white, size: 25))
        ]
        return chartDataPoints
    }


    func remainingDays(for subscription: Subscription) -> Int? {
        guard let startBillDate = subscription.date else {
            return nil
        }

        var nextBillDate = startBillDate
        let today = Date()

        let addYear = subscription.repeatPattern == ContentView.PayRate.yearly.rawValue;

        while nextBillDate <= today {
            if let updatedDate = Calendar.current.date(byAdding: addYear ? .year : .month, value: 1, to: nextBillDate) {
                nextBillDate = updatedDate
            } else {
                return nil
            }
        }
        let calendar = Calendar.current

        let currentDay = calendar.startOfDay(for: today)
        let nextPayment = calendar.startOfDay(for: nextBillDate)
        let components = calendar.dateComponents([.day], from: currentDay, to: nextPayment)
        return components.day ?? 0
    }
}


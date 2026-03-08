import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var store: BlockStore
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var selectedDay: DayData?

    private var history: [DayData] { store.history }

    var body: some View {
        NavigationStack {
            ScrollView {
                if history.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        statsGrid
                        weeklyChart
                        calendarHeatMap
                        selectedDayDetail
                        categoryBreakdown
                        topHabitsList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .animation(.easeInOut(duration: 0.25), value: selectedDay?.date)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("📈")
                .font(.system(size: 48))
            Text("No history yet")
                .font(.headline.weight(.semibold))
            Text("Complete your first day to see trends here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let avg7 = normalizedDayScore(totalReturn: averageReturn(history, days: 7))
        let avgAll = normalizedDayScore(totalReturn: averageReturn(history))
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "7-Day Avg", value: String(format: "%.0f", avg7), color: avg7 >= 70 ? .green : (avg7 >= 40 ? .primary : .orange))
            StatCard(title: "All-Time Avg", value: String(format: "%.0f", avgAll), color: avgAll >= 70 ? .green : (avgAll >= 40 ? .primary : .orange))
            StatCard(title: "Streak", value: "\(store.streak) days", color: .primary)
            StatCard(title: "Best", value: "\(longestStreak(history)) days", color: .primary)
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Score")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let last7 = Array(history.suffix(7))

            if #available(iOS 16.0, *) {
                Chart(last7, id: \.date) { day in
                    let score = normalizedDayScore(totalReturn: day.totalReturn)
                    BarMark(
                        x: .value("Day", String(day.date.suffix(5))),
                        y: .value("Score", score)
                    )
                    .foregroundStyle(score >= 70 ? Color.green : (score >= 40 ? Color.accentColor : Color.orange))
                }
                .frame(height: 140)
            } else {
                Text("Charts require iOS 16+")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Calendar Heat Map

    private var calendarHeatMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 Days")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let days = calendarDays()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            // Day labels
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                    Text(d)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            if let firstDay = days.first {
                LazyVGrid(columns: columns, spacing: 4) {
                    // Padding for day-of-week alignment
                    ForEach(0..<firstDay.dayOfWeek, id: \.self) { _ in
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }

                    ForEach(days, id: \.date) { day in
                        let score = day.data.map { normalizedDayScore(totalReturn: $0.totalReturn) } ?? 0
                        let hasData = day.data != nil

                        RoundedRectangle(cornerRadius: 4)
                            .fill(cellColor(hasData: hasData, score: score))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(selectedDay?.date == day.date ? Color.accentColor : .clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedDay = day.data
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Selected Day Detail

    @ViewBuilder
    private var selectedDayDetail: some View {
        if let day = selectedDay {
            VStack(alignment: .leading, spacing: 12) {
                let dateLabel = formatDate(day.date)
                Text(dateLabel)
                    .font(.headline)

                HStack {
                    let score = normalizedDayScore(totalReturn: day.totalReturn)
                    Text(String(format: "%.0f", score))
                        .font(.title.bold())
                        .foregroundStyle(score >= 70 ? .green : (score >= 40 ? .primary : .orange))
                    Text("/ 100")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("🔥 \(day.streak) day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                let allocs = blocksToAllocations(day.blocks)
                let multiplier = calculateMultiplier(streak: day.streak)

                ForEach(allocs.sorted(by: { $0.value > $1.value }), id: \.key) { habitId, blocks in
                    if let habit = habitById(habitId, from: settingsStore.allHabits) {
                        HStack {
                            Image(systemName: habit.sfSymbol)
                                .font(.subheadline)
                                .foregroundStyle(habit.color)
                                .frame(width: 24, alignment: .center)
                            Text(habit.name)
                                .font(.subheadline)
                            Spacer()
                            Text(blocksToTime(blocks))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            let ret = calculateHabitReturn(habit: habit, blocks: blocks, multiplier: multiplier)
                            Text(String(format: "%+.0f pts", ret))
                                .font(.caption.bold())
                                .foregroundStyle(ret >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        let dist = categoryDistribution(history, allHabits: settingsStore.allHabits)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Category Mix")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                CategoryBar(label: "💎 Blue Chips", pct: dist.essential, color: .blue)
                CategoryBar(label: "📈 Growth", pct: dist.growth, color: .green)
                CategoryBar(label: "⚠️ Drains", pct: dist.drain, color: .red)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top Habits

    private var topHabitsList: some View {
        let top = topHabits(history, allHabits: settingsStore.allHabits, limit: 5)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Most Invested")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                ForEach(top) { entry in
                HStack {
                    Image(systemName: entry.habit.sfSymbol)
                        .font(.title3)
                        .foregroundStyle(entry.habit.color)
                        .frame(width: 24, alignment: .center)
                    VStack(alignment: .leading) {
                        Text(entry.habit.name)
                            .font(.subheadline.bold())
                        Text(String(format: "avg %.1f blocks/day", entry.avgBlocks))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(blocksToTime(entry.totalBlocks)) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    struct CalendarDay {
        let date: String
        let data: DayData?
        let dayOfWeek: Int
    }

    private func calendarDays() -> [CalendarDay] {
        var days: [CalendarDay] = []
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for i in stride(from: 29, through: 0, by: -1) {
            guard let d = Calendar.current.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateStr = formatter.string(from: d)
            let dayData = history.first { $0.date == dateStr }
            let dayOfWeek = Calendar.current.component(.weekday, from: d) - 1 // 0=Sunday

            days.append(CalendarDay(date: dateStr, data: dayData, dayOfWeek: dayOfWeek))
        }

        return days
    }

    private func cellColor(hasData: Bool, score: Double) -> Color {
        guard hasData else { return Color(.systemGray5) }
        if score >= 70 { return Color.green }
        if score >= 40 { return Color.green.opacity(0.6) }
        if score >= 20 { return Color.orange.opacity(0.5) }
        return Color.red.opacity(0.4)
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CategoryBar: View {
    let label: String
    let pct: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f%%", pct))
                .font(.headline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

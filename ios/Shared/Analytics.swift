import Foundation

func averageReturn(_ history: [DayData], days: Int? = nil) -> Double {
    let slice = days != nil ? Array(history.suffix(days!)) : history
    guard !slice.isEmpty else { return 0 }
    return slice.reduce(0.0) { $0 + $1.totalReturn } / Double(slice.count)
}

func bestDay(_ history: [DayData]) -> DayData? {
    history.max(by: { $0.totalReturn < $1.totalReturn })
}

func longestStreak(_ history: [DayData]) -> Int {
    history.map(\.streak).max() ?? 0
}

func habitConsistency(_ history: [DayData], habitId: String) -> Double {
    guard !history.isEmpty else { return 0 }
    let daysUsed = history.filter { day in
        let allocs = blocksToAllocations(day.blocks)
        return (allocs[habitId] ?? 0) > 0
    }.count
    return Double(daysUsed) / Double(history.count) * 100
}

/// Block counts per category for current allocations (used in segmented progress bar)
func categoryBlockCounts(allocations: Allocations, allHabits: [Habit]) -> (essential: Int, growth: Int, drain: Int) {
    var essential = 0, growth = 0, drain = 0
    for (habitId, count) in allocations {
        if let habit = habitById(habitId, from: allHabits) {
            switch habit.category {
            case .essential: essential += count
            case .growth: growth += count
            case .drain: drain += count
            }
        }
    }
    return (essential, growth, drain)
}

func categoryDistribution(_ history: [DayData], allHabits: [Habit]) -> (essential: Double, growth: Double, drain: Double) {
    guard !history.isEmpty else { return (0, 0, 0) }

    var totalBlocks = 0
    var essentialBlocks = 0
    var growthBlocks = 0
    var drainBlocks = 0

    for day in history {
        let allocs = blocksToAllocations(day.blocks)
        for (habitId, count) in allocs {
            if let habit = habitById(habitId, from: allHabits) {
                totalBlocks += count
                switch habit.category {
                case .essential: essentialBlocks += count
                case .growth: growthBlocks += count
                case .drain: drainBlocks += count
                }
            }
        }
    }

    guard totalBlocks > 0 else { return (0, 0, 0) }

    return (
        essential: Double(essentialBlocks) / Double(totalBlocks) * 100,
        growth: Double(growthBlocks) / Double(totalBlocks) * 100,
        drain: Double(drainBlocks) / Double(totalBlocks) * 100
    )
}

func dailyReturnsData(_ history: [DayData]) -> [(date: String, totalReturn: Double)] {
    history.map { (date: $0.date, totalReturn: $0.totalReturn) }
}

struct TopHabitEntry: Identifiable {
    let id: String
    let habit: Habit
    let totalBlocks: Int
    let avgBlocks: Double
}

func topHabits(_ history: [DayData], allHabits: [Habit], limit: Int = 5) -> [TopHabitEntry] {
    guard !history.isEmpty else { return [] }

    var habitTotals: [String: Int] = [:]

    for day in history {
        let allocs = blocksToAllocations(day.blocks)
        for (habitId, count) in allocs {
            habitTotals[habitId, default: 0] += count
        }
    }

    return habitTotals
        .compactMap { (habitId, total) -> TopHabitEntry? in
            guard let habit = habitById(habitId, from: allHabits) else { return nil }
            return TopHabitEntry(
                id: habitId,
                habit: habit,
                totalBlocks: total,
                avgBlocks: Double(total) / Double(history.count)
            )
        }
        .sorted { $0.totalBlocks > $1.totalBlocks }
        .prefix(limit)
        .map { $0 }
}

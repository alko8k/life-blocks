import SwiftUI

// MARK: - Category Progress Bar

struct CategoryProgressBar: View {
    let allocations: Allocations
    let allHabits: [Habit]

    private var counts: (essential: Int, growth: Int, drain: Int) {
        categoryBlockCounts(allocations: allocations, allHabits: allHabits)
    }

    private var totalUsed: Int {
        counts.essential + counts.growth + counts.drain
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let h: CGFloat = 6

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                if totalUsed > 0 {
                    HStack(spacing: 0) {
                        if counts.essential > 0 {
                            Rectangle()
                                .fill(HabitCategory.essential.color)
                                .frame(width: width * CGFloat(counts.essential) / CGFloat(kTotalBlocks))
                        }
                        if counts.growth > 0 {
                            Rectangle()
                                .fill(HabitCategory.growth.color)
                                .frame(width: width * CGFloat(counts.growth) / CGFloat(kTotalBlocks))
                        }
                        if counts.drain > 0 {
                            Rectangle()
                                .fill(HabitCategory.drain.color)
                                .frame(width: width * CGFloat(counts.drain) / CGFloat(kTotalBlocks))
                        }
                    }
                    .frame(height: h)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .frame(height: 6)
    }
}

struct ScoreCardView: View {
    @EnvironmentObject var store: BlockStore
    @EnvironmentObject var settingsStore: SettingsStore

    private var totalReturn: Double {
        calculateTotalReturn(allocations: store.allocations, streak: store.streak, allHabits: settingsStore.allHabits)
    }

    private var dayScore: Double {
        normalizedDayScore(totalReturn: totalReturn)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.0f", dayScore))
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(scoreColor)
                        Text("/ 100")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    Text("\(store.streak)")
                        .font(.subheadline.bold())
                    Text("day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(store.usedBlocks)/\(kTotalBlocks) blocks")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(blocksToTime(store.usedBlocks))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                CategoryProgressBar(allocations: store.allocations, allHabits: settingsStore.allHabits)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scoreColor: Color {
        if dayScore >= 70 { return .green }
        if dayScore >= 40 { return .primary }
        return .orange
    }
}

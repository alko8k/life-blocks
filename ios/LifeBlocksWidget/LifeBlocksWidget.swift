import WidgetKit
import SwiftUI

// MARK: - Timeline

struct BlockGridEntry: TimelineEntry {
    let date: Date
    let blocks: [String?]
    let streak: Int
    let usedBlocks: Int
}

struct BlockGridProvider: TimelineProvider {
    func placeholder(in context: Context) -> BlockGridEntry {
        BlockGridEntry(
            date: Date(),
            blocks: Array(repeating: nil, count: kTotalBlocks),
            streak: 1,
            usedBlocks: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BlockGridEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BlockGridEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> BlockGridEntry {
        let data = BlockStore.loadData()
        return BlockGridEntry(
            date: Date(),
            blocks: data.blocks,
            streak: data.streak,
            usedBlocks: countUsedBlocks(data.blocks)
        )
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: BlockGridEntry

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1.5), count: 10)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Life Blocks")
                    .font(.caption2.bold())
                Spacer()
                Label("\(entry.streak)", systemImage: "flame.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
            }

            LazyVGrid(columns: columns, spacing: 1.5) {
                ForEach(0..<kTotalBlocks, id: \.self) { i in
                    let habit = entry.blocks[i].flatMap { habitById($0) }
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(habit?.color ?? Color(.systemGray5))
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            Text("\(entry.usedBlocks)/\(kTotalBlocks) blocks")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: BlockGridEntry

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1.5), count: 10)

    private var allocations: Allocations {
        blocksToAllocations(entry.blocks)
    }

    private var topHabits: [(Habit, Int)] {
        allocations
            .compactMap { (id, count) in habitById(id).map { ($0, count) } }
            .sorted { $0.1 > $1.1 }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Life Blocks")
                        .font(.caption2.bold())
                    Spacer()
                    Label("\(entry.streak)", systemImage: "flame.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }

                LazyVGrid(columns: columns, spacing: 1.5) {
                    ForEach(0..<kTotalBlocks, id: \.self) { i in
                        let habit = entry.blocks[i].flatMap { habitById($0) }
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(habit?.color ?? Color(.systemGray5))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("\(entry.usedBlocks)/\(kTotalBlocks)")
                    .font(.title3.bold().monospacedDigit())
                Text("blocks used")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                ForEach(topHabits, id: \.0.id) { habit, count in
                    HStack(spacing: 4) {
                        Image(systemName: habit.sfSymbol)
                            .font(.caption)
                            .foregroundStyle(habit.color)
                        Text("\(count)")
                            .font(.caption.monospacedDigit())
                    }
                }
            }
            .frame(width: 70)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget

@main
struct LifeBlocksWidget: Widget {
    let kind = "LifeBlocksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BlockGridProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Life Blocks")
        .description("Today's time block allocation")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BlockGridEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

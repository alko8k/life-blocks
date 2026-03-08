import Foundation
import Combine

private let appGroupID = "group.com.lifeblocks.shared"
private let storageKey = "life-blocks-data"
private let maxHistoryDays = 30

struct StoredData: Codable {
    var currentDate: String
    var blocks: [String?]
    var streak: Int
    var history: [DayData]

    static func empty() -> StoredData {
        StoredData(
            currentDate: todayString(),
            blocks: Array(repeating: nil, count: kTotalBlocks),
            streak: 1,
            history: []
        )
    }

    init(currentDate: String, blocks: [String?], streak: Int, history: [DayData]) {
        self.currentDate = currentDate
        self.blocks = blocks
        self.streak = streak
        self.history = history
    }

    // Handle migration from old format without history
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentDate = try container.decode(String.self, forKey: .currentDate)
        blocks = try container.decode([String?].self, forKey: .blocks)
        streak = try container.decode(Int.self, forKey: .streak)
        history = (try? container.decode([DayData].self, forKey: .history)) ?? []
    }
}

class BlockStore: ObservableObject {
    @Published var blocks: [String?]
    @Published var streak: Int
    @Published var history: [DayData]
    private var currentDate: String

    var allocations: Allocations {
        blocksToAllocations(blocks)
    }

    var usedBlocks: Int {
        countUsedBlocks(blocks)
    }

    var availableBlocks: Int {
        kTotalBlocks - usedBlocks
    }

    init() {
        let data = Self.loadData()
        self.blocks = data.blocks
        self.streak = data.streak
        self.history = data.history
        self.currentDate = data.currentDate
    }

    func addBlock(habitId: String) {
        guard availableBlocks > 0 else { return }
        if let idx = blocks.firstIndex(where: { $0 == nil }) {
            blocks[idx] = habitId
            save()
        }
    }

    func removeBlock(habitId: String) {
        if let idx = blocks.lastIndex(where: { $0 == habitId }) {
            blocks[idx] = nil
            save()
        }
    }

    func addBlocks(habitId: String, count: Int) {
        for _ in 0..<count {
            guard availableBlocks > 0 else { return }
            if let idx = blocks.firstIndex(where: { $0 == nil }) {
                blocks[idx] = habitId
            }
        }
        save()
    }

    /// Set exact block count for a habit (1 block = 10 min). Replaces current allocation.
    func setBlocks(habitId: String, count: Int) {
        let capped = max(0, min(count, kTotalBlocks))
        // Remove all existing blocks for this habit
        for i in blocks.indices where blocks[i] == habitId {
            blocks[i] = nil
        }
        // Add new blocks, respecting total limit
        let otherUsed = blocks.compactMap { $0 }.count
        let toAdd = min(capped, kTotalBlocks - otherUsed)
        var added = 0
        for i in blocks.indices where added < toAdd && blocks[i] == nil {
            blocks[i] = habitId
            added += 1
        }
        save()
    }

    func setBlock(at index: Int, habitId: String?) {
        guard index >= 0, index < kTotalBlocks else { return }
        blocks[index] = habitId
        save()
    }

    func resetToday() {
        blocks = Array(repeating: nil, count: kTotalBlocks)
        save()
    }

    // MARK: - Persistence

    private func save() {
        let data = StoredData(currentDate: currentDate, blocks: blocks, streak: streak, history: history)
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        Self.defaults.set(encoded, forKey: storageKey)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func loadData() -> StoredData {
        guard let data = defaults.data(forKey: storageKey),
              var stored = try? JSONDecoder().decode(StoredData.self, from: data) else {
            return .empty()
        }

        let today = todayString()
        if stored.currentDate != today {
            // Save yesterday's data to history before resetting
            let allocations = blocksToAllocations(stored.blocks)
            let yesterdayReturn = calculateTotalReturn(allocations: allocations, streak: stored.streak)

            let yesterdayData = DayData(
                date: stored.currentDate,
                blocks: stored.blocks,
                streak: stored.streak,
                totalReturn: yesterdayReturn
            )

            let wasYesterday = isYesterday(stored.currentDate)
            var newHistory = stored.history
            newHistory.append(yesterdayData)
            if newHistory.count > maxHistoryDays {
                newHistory = Array(newHistory.suffix(maxHistoryDays))
            }

            stored = StoredData(
                currentDate: today,
                blocks: Array(repeating: nil, count: kTotalBlocks),
                streak: wasYesterday ? stored.streak + 1 : 1,
                history: newHistory
            )
            if let encoded = try? JSONEncoder().encode(stored) {
                defaults.set(encoded, forKey: storageKey)
            }
        }

        return stored
    }
}

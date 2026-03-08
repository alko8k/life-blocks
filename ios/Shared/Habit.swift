import SwiftUI

// MARK: - Types

enum HabitCategory: String, Codable, CaseIterable {
    case essential
    case growth
    case drain

    var label: String {
        switch self {
        case .essential: "Blue Chips"
        case .growth: "Growth"
        case .drain: "Energy Drains"
        }
    }

    var icon: String {
        switch self {
        case .essential: "💎"
        case .growth: "📈"
        case .drain: "⚠️"
        }
    }

    var sfSymbol: String {
        switch self {
        case .essential: return "diamond.fill"
        case .growth: return "chart.bar.fill"
        case .drain: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .essential: return Color.blue
        case .growth: return Color.green
        case .drain: return Color.red
        }
    }
}

struct Habit: Identifiable, Codable, Hashable {
    let id: String
    let emoji: String
    let name: String
    let baseReturn: Double
    let hexColor: String
    let category: HabitCategory
    var isCustom: Bool = false
    var createdAt: String?

    var color: Color {
        Color(hex: hexColor)
    }

    /// SF Symbol for reliable display (emojis can show ? on some devices)
    var sfSymbol: String {
        switch id {
        case "sleep": return "bed.double.fill"
        case "exercise": return "figure.run"
        case "connect": return "bubble.left.and.bubble.right.fill"
        case "deepwork": return "target"
        case "build": return "hammer.fill"
        case "meditate": return "leaf.fill"
        case "reading": return "book.fill"
        case "japanese": return "character.book.closed.fill"
        case "scroll": return "iphone"
        case "netflix": return "tv.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Historical day data

struct DayData: Codable {
    let date: String
    let blocks: [String?]
    let streak: Int
    let totalReturn: Double
}

// MARK: - User Settings

struct UserSettings: Codable {
    var theme: String = "system"
    var customHabits: [Habit] = []
    var onboardingComplete: Bool = false
}

// MARK: - Constants

let kTotalBlocks = 100

/// Base return = per-block impact. Blue Chips 7–9, Growth 4–7, Drains -2.5 to -4
let kDefaultHabits: [Habit] = [
    Habit(id: "sleep", emoji: "😴", name: "Sleep", baseReturn: 8.5, hexColor: "#5E5CE6", category: .essential),
    Habit(id: "exercise", emoji: "🏃", name: "Exercise", baseReturn: 7.5, hexColor: "#FF9F0A", category: .essential),
    Habit(id: "connect", emoji: "💬", name: "Connect", baseReturn: 7.0, hexColor: "#FF6482", category: .essential),
    Habit(id: "deepwork", emoji: "🎯", name: "Deep Work", baseReturn: 6.5, hexColor: "#32ADE6", category: .growth),
    Habit(id: "build", emoji: "⚡", name: "Build", baseReturn: 6.0, hexColor: "#30D158", category: .growth),
    Habit(id: "meditate", emoji: "🧘", name: "Meditate", baseReturn: 5.0, hexColor: "#64D2FF", category: .growth),
    Habit(id: "reading", emoji: "📚", name: "Reading", baseReturn: 4.5, hexColor: "#BF5AF2", category: .growth),
    Habit(id: "japanese", emoji: "🇯🇵", name: "Japanese", baseReturn: 4.0, hexColor: "#FF375F", category: .growth),
    Habit(id: "scroll", emoji: "📱", name: "Scrolling", baseReturn: -3.5, hexColor: "#8E8E93", category: .drain),
    Habit(id: "netflix", emoji: "📺", name: "Binge", baseReturn: -2.5, hexColor: "#636366", category: .drain),
]

/// Backward-compatible reference
let kHabits = kDefaultHabits

let kHabitColors: [String] = [
    "#007AFF", "#5E5CE6", "#32ADE6", "#64D2FF",
    "#34C759", "#30D158", "#FF9F0A", "#FF9500",
    "#FF3B30", "#FF375F", "#FF6482", "#BF5AF2",
    "#AC8E68", "#8E8E93", "#636366",
]

// MARK: - Helpers

func habitById(_ id: String, from habits: [Habit]? = nil) -> Habit? {
    let list = habits ?? kDefaultHabits
    return list.first { $0.id == id }
}

func habitsByCategory(_ category: HabitCategory, from habits: [Habit]? = nil) -> [Habit] {
    let list = habits ?? kDefaultHabits
    return list.filter { $0.category == category }
}

func mergeHabits(custom: [Habit]) -> [Habit] {
    kDefaultHabits + custom
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }
}

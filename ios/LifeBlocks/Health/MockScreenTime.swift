import Foundation

struct ScreenTimeEntry: Identifiable {
    let id = UUID()
    let appName: String
    let icon: String
    let minutes: Int
    let category: String
}

class MockScreenTime: ObservableObject {
    @Published var entries: [ScreenTimeEntry] = [
        ScreenTimeEntry(appName: "Instagram", icon: "camera.fill", minutes: 47, category: "Social"),
        ScreenTimeEntry(appName: "Twitter/X", icon: "bubble.left.fill", minutes: 35, category: "Social"),
        ScreenTimeEntry(appName: "YouTube", icon: "play.rectangle.fill", minutes: 58, category: "Entertainment"),
        ScreenTimeEntry(appName: "Netflix", icon: "tv.fill", minutes: 82, category: "Entertainment"),
        ScreenTimeEntry(appName: "TikTok", icon: "music.note", minutes: 31, category: "Social"),
        ScreenTimeEntry(appName: "Safari", icon: "globe", minutes: 24, category: "Productivity"),
        ScreenTimeEntry(appName: "Messages", icon: "message.fill", minutes: 18, category: "Communication"),
    ]

    var totalMinutes: Int { entries.reduce(0) { $0 + $1.minutes } }

    var socialMinutes: Int {
        entries.filter { $0.category == "Social" }.reduce(0) { $0 + $1.minutes }
    }

    var entertainmentMinutes: Int {
        entries.filter { $0.category == "Entertainment" }.reduce(0) { $0 + $1.minutes }
    }

    var suggestedScrollBlocks: Int {
        // Social media -> "Scrolling" habit
        Int(ceil(Double(socialMinutes) / 10.0))
    }

    var suggestedBingeBlocks: Int {
        // Entertainment -> "Binge" habit
        Int(ceil(Double(entertainmentMinutes) / 10.0))
    }
}

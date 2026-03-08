import Foundation
import Combine

private let appGroupID = "group.com.lifeblocks.shared"
private let settingsKey = "life-blocks-settings"

class SettingsStore: ObservableObject {
    @Published var settings: UserSettings

    var allHabits: [Habit] {
        mergeHabits(custom: settings.customHabits)
    }

    init() {
        self.settings = Self.loadSettings()
    }

    func updateTheme(_ theme: String) {
        var updated = settings
        updated.theme = theme
        settings = updated
        save()
    }

    func completeOnboarding() {
        settings.onboardingComplete = true
        save()
    }

    func addCustomHabit(_ habit: Habit) {
        var h = habit
        h.isCustom = true
        h.createdAt = ISO8601DateFormatter().string(from: Date())
        settings.customHabits.append(h)
        save()
    }

    func removeCustomHabit(id: String) {
        settings.customHabits.removeAll { $0.id == id }
        save()
    }

    func editCustomHabit(id: String, emoji: String, name: String, baseReturn: Double, hexColor: String, category: HabitCategory) {
        if let idx = settings.customHabits.firstIndex(where: { $0.id == id }) {
            let old = settings.customHabits[idx]
            settings.customHabits[idx] = Habit(
                id: old.id,
                emoji: emoji,
                name: name,
                baseReturn: baseReturn,
                hexColor: hexColor,
                category: category,
                isCustom: true,
                createdAt: old.createdAt
            )
            save()
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let encoded = try? JSONEncoder().encode(settings) else { return }
        Self.defaults.set(encoded, forKey: settingsKey)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static func loadSettings() -> UserSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }
}

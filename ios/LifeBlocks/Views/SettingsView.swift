import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var store: BlockStore
    @State private var showHabitEditor = false
    @State private var editingHabit: Habit?
    @State private var showResetAlert = false
    @State private var showImporter = false
    @State private var importMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: Binding(
                        get: { settingsStore.settings.theme },
                        set: { settingsStore.updateTheme($0) }
                    )) {
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                }

                // Habits
                Section("Habits") {
                    ForEach(settingsStore.allHabits, id: \.id) { habit in
                        HStack {
                            Image(systemName: habit.sfSymbol)
                                .font(.title3)
                                .foregroundStyle(habit.color)
                                .frame(width: 28, alignment: .center)
                            VStack(alignment: .leading) {
                                Text(habit.name)
                                    .font(.subheadline.bold())
                                Text(String(format: "%+.1f/block · %@", habit.baseReturn, habit.category.label))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if habit.isCustom {
                                Button("Edit") {
                                    editingHabit = habit
                                    showHabitEditor = true
                                }
                                .font(.caption)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let allHabits = settingsStore.allHabits
                        for offset in offsets {
                            let habit = allHabits[offset]
                            if habit.isCustom {
                                settingsStore.removeCustomHabit(id: habit.id)
                            }
                        }
                    }

                    Button {
                        editingHabit = nil
                        showHabitEditor = true
                    } label: {
                        Label("Add Custom Habit", systemImage: "plus.circle")
                    }
                }

                // Data
                Section("Data") {
                    ShareLink(item: exportString()) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showImporter = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }

                    if let msg = importMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                }

                // About
                Section("About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Life Blocks")
                            .font(.headline)
                        Text("Invest your time like a portfolio. 100 blocks. Make them count.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Version 2.0")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showHabitEditor) {
                HabitEditorView(editHabit: editingHabit)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    let defaults = UserDefaults(suiteName: "group.com.lifeblocks.shared") ?? .standard
                    defaults.removeObject(forKey: "life-blocks-data")
                    defaults.removeObject(forKey: "life-blocks-settings")
                    // Reset in-memory state
                    store.resetToday()
                    store.streak = 1
                    store.history = []
                    settingsStore.settings = UserSettings()
                }
            } message: {
                Text("This will delete all your history, custom habits, and settings. This cannot be undone.")
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
        }
    }

    private func exportString() -> String {
        struct ExportData: Codable {
            let version: Int
            let exportDate: String
            let settings: UserSettings
            let blocks: [String?]
            let streak: Int
            let history: [DayData]
        }

        let exportData = ExportData(
            version: 2,
            exportDate: ISO8601DateFormatter().string(from: Date()),
            settings: settingsStore.settings,
            blocks: store.blocks,
            streak: store.streak,
            history: store.history
        )

        if let data = try? JSONEncoder().encode(exportData),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importMessage = "Cannot access file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let settings = try JSONDecoder().decode(UserSettings.self, from: data)
                settingsStore.settings = settings
                importMessage = "Import successful!"
            } catch {
                importMessage = "Invalid file format"
            }

        case .failure:
            importMessage = "Failed to open file"
        }
    }
}

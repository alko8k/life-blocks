import SwiftUI

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStore

    let editHabit: Habit?

    @State private var emoji: String
    @State private var name: String
    @State private var baseReturn: Double
    @State private var category: HabitCategory
    @State private var selectedColor: String

    init(editHabit: Habit? = nil) {
        self.editHabit = editHabit
        _emoji = State(initialValue: editHabit?.emoji ?? "")
        _name = State(initialValue: editHabit?.name ?? "")
        _baseReturn = State(initialValue: editHabit?.baseReturn ?? 5.0)
        _category = State(initialValue: editHabit?.category ?? .growth)
        _selectedColor = State(initialValue: editHabit?.hexColor ?? kHabitColors[0])
    }

    private var isValid: Bool {
        !emoji.trimmingCharacters(in: .whitespaces).isEmpty && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    TextField("Pick an emoji", text: $emoji)
                        .font(.system(size: 32))
                        .multilineTextAlignment(.center)
                }

                Section("Name") {
                    TextField("Habit name", text: $name)
                }

                Section("Per-block impact: \(String(format: "%+.1f", baseReturn))") {
                    Slider(value: $baseReturn, in: -5...10, step: 0.1)
                    HStack {
                        Text("-5%").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("0%").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("+10%").font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(HabitCategory.allCases, id: \.self) { cat in
                            Text("\(cat.icon) \(cat.label)").tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(kHabitColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .strokeBorder(selectedColor == hex ? Color.primary : .clear, lineWidth: 3)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                }

                if isValid {
                    Section("Preview") {
                        HStack {
                            Text(emoji)
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text(name).font(.headline)
                                Text("\(category.icon) \(category.label)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%+.1f", baseReturn))
                                .font(.headline)
                                .foregroundStyle(baseReturn >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle(editHabit != nil ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let habit = Habit(
            id: editHabit?.id ?? UUID().uuidString,
            emoji: emoji.trimmingCharacters(in: .whitespaces),
            name: name.trimmingCharacters(in: .whitespaces),
            baseReturn: baseReturn,
            hexColor: selectedColor,
            category: category,
            isCustom: true,
            createdAt: editHabit?.createdAt
        )

        if editHabit != nil {
            settingsStore.editCustomHabit(
                id: habit.id,
                emoji: habit.emoji,
                name: habit.name,
                baseReturn: habit.baseReturn,
                hexColor: habit.hexColor,
                category: habit.category
            )
        } else {
            settingsStore.addCustomHabit(habit)
        }

        dismiss()
    }
}

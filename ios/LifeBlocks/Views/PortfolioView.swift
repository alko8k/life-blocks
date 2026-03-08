import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var store: BlockStore
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var expandedCategories: Set<HabitCategory> = Set(HabitCategory.allCases)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Portfolio")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            ForEach(Array(HabitCategory.allCases.enumerated()), id: \.element) { index, category in
                CategorySection(
                    category: category,
                    habits: habitsByCategory(category, from: settingsStore.allHabits),
                    allocations: store.allocations,
                    isExpanded: Binding(
                        get: { expandedCategories.contains(category) },
                        set: { if $0 { expandedCategories.insert(category) } else { expandedCategories.remove(category) } }
                    ),
                    isFirst: index == 0
                )
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CategorySection: View {
    let category: HabitCategory
    let habits: [Habit]
    let allocations: [String: Int]
    @Binding var isExpanded: Bool
    var isFirst: Bool = true

    private var blockCount: Int {
        habits.reduce(0) { sum, h in sum + (allocations[h.id] ?? 0) }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 6) {
                ForEach(habits, id: \.id) { habit in
                    HabitRow(habit: habit, blocks: allocations[habit.id] ?? 0)
                }
            }
            .padding(.top, 8)
            .padding(.leading, 4)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: category.sfSymbol)
                    .font(.subheadline)
                    .foregroundStyle(category.color)
                    .frame(width: 24, alignment: .center)

                Text(category.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if blockCount > 0 {
                    Text("\(blockCount) blocks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(category.color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 6)
        }
        .disclosureGroupStyle(CategoryDisclosureStyle())
        .padding(.top, isFirst ? 0 : 8)
        .padding(.bottom, 12)
    }
}

struct CategoryDisclosureStyle: DisclosureGroupStyle {
    private static let anim = Animation.spring(response: 0.4, dampingFraction: 0.9)

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(Self.anim) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    configuration.label

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(configuration.isExpanded ? 0 : -90))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if configuration.isExpanded {
                configuration.content
                    .transition(.opacity)
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(Self.anim, value: configuration.isExpanded)
    }
}

struct HabitRow: View {
    let habit: Habit
    let blocks: Int
    @EnvironmentObject var store: BlockStore
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    private var isSleep: Bool { habit.id == "sleep" }
    private var unitLabel: String { isSleep ? "hr" : "min" }

    private var multiplier: Double {
        calculateMultiplier(streak: store.streak)
    }

    private var categoryColor: Color {
        habit.category.color
    }

    private var displayValue: String {
        if blocks <= 0 { return "" }
        if isSleep {
            let hours = Double(blocks * 10) / 60
            return hours.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(hours))"
                : String(format: "%.1f", hours)
        }
        return "\(blocks * 10)"
    }

    private func blocksFromInput(_ text: String) -> Int {
        guard let value = Double(text), value >= 0 else { return 0 }
        if isSleep { return Int(value * 6) }
        return Int(value) / 10
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.sfSymbol)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.subheadline.weight(.medium))
                if blocks > 0 {
                    let returnVal = calculateHabitReturn(habit: habit, blocks: blocks, multiplier: multiplier)
                    Text("\(blocksToTime(blocks)) · \(String(format: "%+.0f", returnVal)) pts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(format: "%+.1f", habit.baseReturn) + "/block")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                TextField("0", text: $inputText)
                    .keyboardType(isSleep ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.center)
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .frame(width: 52)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($isInputFocused)
                    .onSubmit { applyInput() }
                    .onChange(of: isInputFocused) { _, focused in
                        if !focused { applyInput() }
                    }
                    .onChange(of: blocks) { _, newBlocks in
                        if !isInputFocused {
                            if newBlocks > 0 {
                                if isSleep {
                                    let hours = Double(newBlocks * 10) / 60
                                    inputText = hours.truncatingRemainder(dividingBy: 1) == 0
                                        ? "\(Int(hours))"
                                        : String(format: "%.1f", hours)
                                } else {
                                    inputText = "\(newBlocks * 10)"
                                }
                            } else {
                                inputText = ""
                            }
                        }
                    }
                    .onAppear {
                        if blocks > 0 {
                            if isSleep {
                                let hours = Double(blocks * 10) / 60
                                inputText = hours.truncatingRemainder(dividingBy: 1) == 0
                                    ? "\(Int(hours))"
                                    : String(format: "%.1f", hours)
                            } else {
                                inputText = "\(blocks * 10)"
                            }
                        } else {
                            inputText = ""
                        }
                    }
                Text(unitLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 28, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(categoryColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func applyInput() {
        guard let value = Double(inputText), value >= 0 else {
            inputText = displayValue
            return
        }
        let newBlocks = blocksFromInput(inputText)
        store.setBlocks(habitId: habit.id, count: newBlocks)
        if newBlocks > 0 {
            if isSleep {
                let hours = Double(newBlocks * 10) / 60
                inputText = hours.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(hours))"
                    : String(format: "%.1f", hours)
            } else {
                inputText = "\(newBlocks * 10)"
            }
        } else {
            inputText = ""
        }
    }
}

import SwiftUI

struct BlockGridView: View {
    @EnvironmentObject var store: BlockStore
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHabit: Habit? = nil
    @State private var isDragging = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 10)
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(store.usedBlocks) used")
                                .foregroundStyle(.primary)
                            Text("\u{2022}")
                                .foregroundStyle(.secondary)
                            Text("\(store.availableBlocks) left")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)

                        // 10x10 grid with drag support
                        GeometryReader { geometry in
                            let gridWidth = geometry.size.width
                            let cellSize = (gridWidth - 4 * 9) / 10

                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(0..<kTotalBlocks, id: \.self) { index in
                                    BlockCell(
                                        habitId: store.blocks[index],
                                        selectedHabit: selectedHabit,
                                        allHabits: settingsStore.allHabits
                                    )
                                    .onTapGesture {
                                        handleTap(at: index)
                                        feedbackGenerator.impactOccurred(intensity: 0.5)
                                    }
                                }
                            }
                            .animation(.easeOut(duration: 0.15), value: store.blocks)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        isDragging = true
                                        let location = value.location
                                        if let index = indexFromPoint(location, cellSize: cellSize, gridWidth: gridWidth) {
                                            let currentValue = store.blocks[index]
                                            let newValue = selectedHabit?.id
                                            if currentValue != newValue {
                                                handleTap(at: index)
                                                feedbackGenerator.impactOccurred(intensity: 0.4)
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                    }
                            )
                        }
                        .aspectRatio(1, contentMode: .fit)

                        HStack {
                            Text("12 AM")
                            Spacer()
                            Text("12 PM")
                            Spacer()
                            Text("11:50 PM")
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                        // Mini legend
                        MiniLegend(habits: settingsStore.allHabits)
                    }
                    .padding()
                }

                Divider()

                // Habit picker strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Eraser
                        Button {
                            selectedHabit = nil
                            feedbackGenerator.impactOccurred(intensity: 0.5)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "eraser.fill")
                                    .font(.title2)
                                Text("Clear")
                                    .font(.caption2)
                            }
                            .frame(width: 56, height: 56)
                            .background(selectedHabit == nil ? Color(.systemGray4) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        ForEach(settingsStore.allHabits, id: \.id) { habit in
                            Button {
                                selectedHabit = habit
                                feedbackGenerator.impactOccurred(intensity: 0.5)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: habit.sfSymbol)
                                        .font(.title2)
                                        .foregroundStyle(habit.color)
                                    Text(habit.name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .frame(width: 56, height: 56)
                                .background(selectedHabit?.id == habit.id ? habit.color.opacity(0.3) : Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selectedHabit?.id == habit.id ? habit.color : .clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        store.resetToday()
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    private func handleTap(at index: Int) {
        if let habit = selectedHabit {
            store.setBlock(at: index, habitId: habit.id)
        } else {
            store.setBlock(at: index, habitId: nil)
        }
    }

    private func indexFromPoint(_ point: CGPoint, cellSize: CGFloat, gridWidth: CGFloat) -> Int? {
        let spacing: CGFloat = 4
        let step = cellSize + spacing

        let col = Int(point.x / step)
        let row = Int(point.y / step)

        guard col >= 0, col < 10, row >= 0, row < 10 else { return nil }

        let index = row * 10 + col
        guard index >= 0, index < kTotalBlocks else { return nil }
        return index
    }
}

struct BlockCell: View {
    let habitId: String?
    let selectedHabit: Habit?
    var allHabits: [Habit] = kDefaultHabits

    var body: some View {
        let habit = habitId.flatMap { habitById($0, from: allHabits) }

        RoundedRectangle(cornerRadius: 3)
            .fill(habit?.color ?? Color(.systemGray5))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let habit {
                    Image(systemName: habit.sfSymbol)
                        .font(.system(size: 6))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
    }
}

struct MiniLegend: View {
    var habits: [Habit] = kDefaultHabits

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(habits, id: \.id) { habit in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(habit.color)
                        .frame(width: 12, height: 12)
                    Text(habit.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
}

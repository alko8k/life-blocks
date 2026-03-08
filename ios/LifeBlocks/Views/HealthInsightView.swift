import SwiftUI

private let barHeight: CGFloat = 8
private let maxScreenTimeItems = 5
private let drainColor = Color.red

struct HealthInsightView: View {
    @EnvironmentObject var store: BlockStore
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var screenTime: MockScreenTime
    @State private var appeared = false

    private var healthMaxMinutes: Double {
        max(healthManager.sleepHours * 60, healthManager.workoutMinutes, 60)
    }

    private var screenTimeMaxMinutes: Double {
        max(Double(screenTime.entries.map(\.minutes).max() ?? 60), 60)
    }

    private var topScreenTimeEntries: [ScreenTimeEntry] {
        Array(screenTime.entries.sorted { $0.minutes > $1.minutes }.prefix(maxScreenTimeItems))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if healthManager.isAuthorized {
                VStack(alignment: .leading, spacing: 12) {
                    HealthBarRow(
                        icon: "bed.double.fill",
                        title: "Sleep",
                        value: healthManager.sleepHours * 60,
                        maxValue: healthMaxMinutes,
                        unit: "h",
                        color: .indigo,
                        appeared: appeared,
                        addLabel: "+\(healthManager.suggestedSleepBlocks)",
                        onAdd: { store.addBlocks(habitId: "sleep", count: healthManager.suggestedSleepBlocks) }
                    )
                    HealthBarRow(
                        icon: "figure.run",
                        title: "Workout",
                        value: healthManager.workoutMinutes,
                        maxValue: healthMaxMinutes,
                        unit: "m",
                        color: .green,
                        appeared: appeared,
                        addLabel: "+\(healthManager.suggestedExerciseBlocks)",
                        onAdd: { store.addBlocks(habitId: "exercise", count: healthManager.suggestedExerciseBlocks) }
                    )
                }
            } else if healthManager.isAvailable {
                Button {
                    healthManager.requestAuthorization()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        Text("Connect Health")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            if !screenTime.entries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    if healthManager.isAuthorized || healthManager.isAvailable {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                            .padding(.vertical, 4)
                    }

                    Text("Screen Time")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)

                    ForEach(topScreenTimeEntries) { entry in
                        ScreenTimeBarRow(
                            title: entry.appName,
                            value: Double(entry.minutes),
                            maxValue: screenTimeMaxMinutes,
                            color: drainColor,
                            appeared: appeared
                        )
                    }

                    HStack(spacing: 8) {
                        QuickAddButton(title: "Scrolling", blocks: screenTime.suggestedScrollBlocks) {
                            store.addBlocks(habitId: "scroll", count: screenTime.suggestedScrollBlocks)
                        }
                        QuickAddButton(title: "Binge", blocks: screenTime.suggestedBingeBlocks) {
                            store.addBlocks(habitId: "netflix", count: screenTime.suggestedBingeBlocks)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
}

// MARK: - Health Bar Row

struct HealthBarRow: View {
    let icon: String
    let title: String
    let value: Double
    let maxValue: Double
    let unit: String
    let color: Color
    var appeared: Bool
    var addLabel: String
    var onAdd: () -> Void

    private var barFraction: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(min(1, value / maxValue))
    }

    private var displayValue: String {
        if unit == "h" { return String(format: "%.1fh", value / 60) }
        return "\(Int(value))\(unit)"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 20, alignment: .center)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: appeared ? max(4, geo.size.width * barFraction) : 0,
                            height: barHeight
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)

            Text(displayValue)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)

            Button(action: onAdd) {
                Text(addLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: value)
    }
}

// MARK: - Screen Time Bar Row (no track, bar only)

struct ScreenTimeBarRow: View {
    let title: String
    let value: Double
    let maxValue: Double
    let color: Color
    var appeared: Bool

    private var barFraction: CGFloat {
        guard maxValue > 0, value > 0 else { return 0 }
        return CGFloat(min(1, value / maxValue))
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: appeared ? max(4, geo.size.width * barFraction) : 0,
                            height: barHeight
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)

            Text("\(Int(value))m")
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: value)
    }
}

// MARK: - Quick Add Buttons

struct QuickAddButton: View {
    let title: String
    let blocks: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.medium))
                Text("+\(blocks)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemGroupedBackground))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

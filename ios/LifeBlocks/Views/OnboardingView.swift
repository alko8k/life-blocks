import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var currentPage = 0

    private let pages: [(symbol: String, title: String, subtitle: String, description: String)] = [
        ("chart.bar.fill", "Life Blocks", "Invest your time like a portfolio",
         "Think of your day as a portfolio of investments. Allocate your time wisely and watch your returns compound."),
        ("square.grid.3x3.fill", "100 Blocks a Day", "You have 16.6 waking hours",
         "Each block is 10 minutes. You have exactly 100 blocks from 6 AM to 10:40 PM. How will you invest them?"),
        ("diamond.fill", "Three Categories", "Blue Chips, Growth & Drains",
         "Blue Chips are essentials like sleep and exercise. Growth habits build your future. Drains cost you returns."),
        ("flame.fill", "Streaks Compound", "Consistency multiplies returns",
         "Every consecutive day increases your multiplier. A 7-day streak nearly doubles your returns. Stay consistent."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    settingsStore.completeOnboarding()
                }
                .foregroundStyle(.secondary)
                .font(.callout.weight(.medium))
                .padding()
            }

            Spacer()

            // Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 16) {
                        Image(systemName: pages[index].symbol)
                            .font(.system(size: 56))
                            .foregroundStyle(Color.accentColor)
                            .padding(.bottom, 8)

                        Text(pages[index].title)
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(pages[index].subtitle)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                            .multilineTextAlignment(.center)

                        Text(pages[index].description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            Spacer()

            // Bottom controls
            VStack(spacing: 20) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.accentColor : Color(.systemGray4))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }

                // Action button
                Button {
                    if currentPage == pages.count - 1 {
                        settingsStore.completeOnboarding()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                } label: {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 48)
        }
    }
}

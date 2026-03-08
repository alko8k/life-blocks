import SwiftUI
import WidgetKit

struct HomeView: View {
    @EnvironmentObject var store: BlockStore
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var healthManager: HealthManager
    @State private var showBlockGrid = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ScoreCardView()
                    PortfolioView()
                    HealthInsightView()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBlockGrid = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.body.weight(.medium))
                    }
                }
            }
            .sheet(isPresented: $showBlockGrid) {
                BlockGridView()
                    .presentationDetents([.large])
                    .presentationCornerRadius(24)
                    .presentationDragIndicator(.visible)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showBlockGrid = true
                } label: {
                    Text("Schedule Your Day")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.usedBlocks)
        .onChange(of: store.blocks) { _, _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

import SwiftUI
import UIKit

@main
struct LifeBlocksApp: App {
    @StateObject private var store = BlockStore()
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var healthManager = HealthManager()
    @StateObject private var screenTime = MockScreenTime()

    private var resolvedColorScheme: ColorScheme? {
        switch settingsStore.settings.theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // system
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if settingsStore.settings.onboardingComplete {
                    TabView {
                        HomeView()
                            .tabItem {
                                Image(systemName: "chart.bar.fill")
                                Text("Today")
                            }

                        HistoryView()
                            .tabItem {
                                Image(systemName: "calendar")
                                Text("History")
                            }

                        SettingsView()
                            .tabItem {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }
                    }
                    .tabViewStyle(.automatic)
                } else {
                    OnboardingView()
                }
            }
            .animation(.easeInOut(duration: 0.35), value: settingsStore.settings.onboardingComplete)
            .preferredColorScheme(resolvedColorScheme)
            .environmentObject(store)
            .environmentObject(settingsStore)
            .environmentObject(healthManager)
            .environmentObject(screenTime)
            .onAppear { applyThemeToWindow() }
            .onChange(of: settingsStore.settings.theme) { _, _ in applyThemeToWindow() }
        }
    }

    private func applyThemeToWindow() {
        let style: UIUserInterfaceStyle = switch settingsStore.settings.theme {
        case "dark": .dark
        case "light": .light
        default: .unspecified
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

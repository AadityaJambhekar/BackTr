import SwiftUI

@main
struct BacktestAppApp: App {
    @State private var showHome = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showHome {
                    HomeView(showHome: $showHome)
                        .transition(.opacity)
                } else {
                    ContentView(showHome: $showHome)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showHome)
            .task {
                await BacktestService().logOpen()
            }
        }
    }
}

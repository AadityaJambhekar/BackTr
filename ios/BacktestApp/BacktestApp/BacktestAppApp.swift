import SwiftUI

@main
struct BacktestAppApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Back\u{200B}tr")
                    .font(.system(size: 38, weight: .bold, design: .default))
                    .kerning(-1)
                    .overlay(
                        LinearGradient(
                            colors: [.white, .white, Color.backtrAccent],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .mask(
                            Text("Backtr")
                                .font(.system(size: 38, weight: .bold))
                                .kerning(-1)
                        )
                    )
                Text("Backtest smarter.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.backtrSub)
            }
        }
    }
}

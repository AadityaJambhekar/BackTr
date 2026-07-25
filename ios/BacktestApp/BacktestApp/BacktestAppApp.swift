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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()

            VStack(spacing: 16) {
                // Logo mark — square with "B"
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.backtrAccent)
                        .frame(width: 72, height: 72)
                    Text("B")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                }

                // App name
                HStack(spacing: 0) {
                    Text("Back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .kerning(-0.8)
                    Text("tr")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.backtrAccent)
                        .kerning(-0.8)
                }

                Text("Backtest smarter.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.backtrSub)
            }
        }
    }
}

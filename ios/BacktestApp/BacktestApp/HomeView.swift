import SwiftUI

struct HomeView: View {
    @Binding var showHome: Bool
    @State private var showHowItWorks = false
    @State private var showTerms = false

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // Logo
                VStack(spacing: 14) {
                    Image("LogoMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    HStack(spacing: 0) {
                        Text("Back")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .kerning(-0.8)
                        Text("tr")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.backtrAccent)
                            .kerning(-0.8)
                    }

                    Text("Test any stock strategy. See real results.")
                        .font(.system(size: 15))
                        .foregroundColor(.backtrSub)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Actions
                VStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showHome = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.backtrAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.tap()
                        showHowItWorks = true
                    } label: {
                        Text("How It Works")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.backtrSub)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.backtrCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.backtrBorder, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 20)

                Button {
                    Haptics.tap()
                    showTerms = true
                } label: {
                    Text("Terms of Service")
                        .font(.system(size: 12))
                        .foregroundColor(.backtrMuted)
                        .underline()
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 40)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showHowItWorks) { HowItWorksView() }
        .sheet(isPresented: $showTerms) { TermsOfServiceView() }
    }
}

struct StepRow: View {
    let number: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.backtrAccent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.backtrAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.backtrMuted)
            }
        }
    }
}

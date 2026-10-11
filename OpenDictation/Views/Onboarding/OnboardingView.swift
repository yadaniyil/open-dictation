import AVFoundation
import SwiftUI

/// The first-launch screens: the pages side by side, the page dots, and what the buttons do.
struct OnboardingView: View {
    /// Called once the user has agreed and answered the microphone question.
    let finish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var current = 0
    @State private var isFinishing = false
    @State private var isTurningPage = false

    private let pages = OnboardingPage.all

    var body: some View {
        VStack(spacing: 0) {
            // A page-style TabView, because its selection always matches the page on screen.
            // A paging ScrollView lost track when a finger landed in the middle of a page turn.
            TabView(selection: $current) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index], isBusy: isFinishing || isTurningPage) {
                        buttonTapped(onPageAt: index)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageDots(count: pages.count, index: current) { show(pageAt: $0) }
                .padding(.bottom, OnboardingStyle.dotsBottomMargin)
        }
        .background(OnboardingStyle.background.ignoresSafeArea())
    }

    private func buttonTapped(onPageAt index: Int) {
        if pages[index].id == OnboardingPage.consent.id {
            agree()
        } else {
            show(pageAt: index + 1)
        }
    }

    /// The buttons rest while the page turns, so a double tap on "Continue" can never land on
    /// "I agree" as it slides in.
    private func show(pageAt index: Int) {
        guard pages.indices.contains(index) else { return }
        isTurningPage = true
        withAnimation(reduceMotion ? nil : .default) { current = index }
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            isTurningPage = false
        }
    }

    /// Stores the agreement, then lets iOS ask for the microphone while the reason is fresh.
    private func agree() {
        OnboardingState.standard.agreeToCloudProcessing()
        isFinishing = true
        Task {
            if AVAudioApplication.shared.recordPermission == .undetermined {
                _ = await AVAudioApplication.requestRecordPermission()
            }
            // A "no" does not hold the user here: the main screen says what to do about it.
            finish()
        }
    }
}

/// Dots that show which page is in front: the current one is a short pill.
/// VoiceOver reads them as one adjustable control.
private struct PageDots: View {
    let count: Int
    let index: Int
    let show: (Int) -> Void

    var body: some View {
        HStack(spacing: OnboardingStyle.dotSpacing) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? OnboardingStyle.tint : OnboardingStyle.dot)
                    .frame(
                        width: dot == index ? OnboardingStyle.currentDotWidth : OnboardingStyle.dotSize,
                        height: OnboardingStyle.dotSize)
            }
        }
        .animation(.snappy, value: index)
        .accessibilityElement()
        .accessibilityLabel("Page")
        .accessibilityValue("\(index + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: show(index + 1)
            case .decrement: show(index - 1)
            @unknown default: break
            }
        }
    }
}

extension View {
    /// Covers this view with the first-launch screens until the user has been through them.
    func onboarding() -> some View {
        modifier(OnboardingCover())
    }
}

/// Not a `fullScreenCover`: that slides in after launch, so the main screen would flash first.
private struct OnboardingCover: ViewModifier {
    @State private var isShown = OnboardingState.standard.needsOnboarding

    func body(content: Content) -> some View {
        ZStack {
            content
                // Keeps VoiceOver out of the main screen while it is covered.
                .accessibilityHidden(isShown)

            if isShown {
                OnboardingView {
                    withAnimation { isShown = false }
                    Task { await FirstModelDownload.startIfSensible() }
                }
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    OnboardingView {}
}

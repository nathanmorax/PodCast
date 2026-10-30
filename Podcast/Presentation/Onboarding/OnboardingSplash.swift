//
//  OnboardingSplash.swift
//  Podcast
//

import SwiftUI

/// The "Tell me more" phrase from the app icon, as text: "Tell me", "more" in
/// italic green, and a short underline. Used big for the first-launch splash
/// and small in the corner of the onboarding.
///
/// `step` decides how much of it is shown, so the splash can build it piece
/// by piece; the small, settled version passes `.settled` and shows it all.
struct TellMeMoreMark: View {

    var size: CGFloat
    var step: OnboardingIntro.Step = .settled
    /// "Tell me" and the underline. "more" is always the accent ink.
    var ink: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "Tell me")
                .font(.system(size: size, design: .serif))
                .foregroundStyle(ink)
                .opacity(step >= .tell ? 1 : 0)
                .offset(y: step >= .tell ? 0 : size * 0.15)

            Text(verbatim: "more")
                .font(.system(size: size, design: .serif).italic())
                .foregroundStyle(AppColor.accentInk)
                .opacity(step >= .more ? 1 : 0)
                .offset(x: step >= .more ? 0 : -size * 0.2)

            Capsule()
                .fill(ink)
                .frame(width: size * 1.1, height: max(2, size * 0.09))
                .scaleEffect(x: step >= .underline ? 1 : 0.001, anchor: .leading)
                .padding(.top, size * 0.08)
        }
        .tracking(-size * 0.015)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Tell me more"))
        .accessibilityAddTraits(.isHeader)
    }
}

/// Where the first-launch splash is. It plays once each time the onboarding
/// opens on its own (not from Home's "Edit"):
///
/// 1. On the launch-screen color, the phrase forms: "Tell me" → "more" →
///    the underline draws.
/// 2. `moving`: the background turns into the onboarding color, the phrase
///    shrinks into the top-left corner and the genres come in.
/// 3. `settled`: the small phrase lives in the scroll content from then on.
///
/// With Reduce Motion it starts at `settled`: no splash, just the screen.
struct OnboardingIntro {

    enum Step: Int, Comparable {
        case hidden, tell, more, underline, moving, settled
        static func < (a: Step, b: Step) -> Bool { a.rawValue < b.rawValue }
    }

    /// Size of the big phrase and of the one in the corner.
    static let bigSize: CGFloat = 56
    static let smallSize: CGFloat = 24
    /// Distance of the small phrase from the top-left corner (safe area).
    static let cornerInset = EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 0)

    var step: Step

    /// The splash covers the screen (phrase centered, launch color behind).
    var isSplash: Bool { step < .moving }
    /// The genres, the button… everything below the phrase.
    var showsContent: Bool { step >= .moving }

    init(plays: Bool) {
        step = plays ? .hidden : .settled
    }
}

/// The animated sequence, kept out of `OnboardingView`. It drives the intro
/// through a binding so the view only reads `intro.step`.
@MainActor
enum OnboardingIntroPlayer {

    static func play(_ intro: Binding<OnboardingIntro>) async {
        guard intro.wrappedValue.step == .hidden else { return }
        let steps: [(OnboardingIntro.Step, Duration)] = [
            (.tell, .milliseconds(250)),
            (.more, .milliseconds(450)),
            (.underline, .milliseconds(450)),
        ]
        for (step, wait) in steps {
            do { try await Task.sleep(for: wait) } catch { return }
            withAnimation(.spring(duration: 0.5, bounce: 0)) { intro.wrappedValue.step = step }
        }
        // Hold the full phrase a moment, then go to the corner.
        do { try await Task.sleep(for: .milliseconds(900)) } catch { return }
        moveToCorner(intro)
    }

    /// Also used by a tap on the splash, to skip it.
    static func moveToCorner(_ intro: Binding<OnboardingIntro>) {
        guard intro.wrappedValue.step < .moving else { return }
        withAnimation(.spring(duration: 0.7, bounce: 0)) {
            intro.wrappedValue.step = .moving
        } completion: {
            intro.wrappedValue.step = .settled
        }
    }
}

/// The big phrase over the launch color. It sits centered while forming, then
/// slides and shrinks into the corner, exactly where the small one lives in
/// the scroll content, and the view swaps them when the move ends.
struct OnboardingSplashLayer: View {

    @Binding var intro: OnboardingIntro

    private var scale: CGFloat { OnboardingIntro.smallSize / OnboardingIntro.bigSize }

    var body: some View {
        ZStack {
            AppColor.screenBackground
                .ignoresSafeArea()
                .opacity(intro.isSplash ? 1 : 0)

            TellMeMoreMark(
                size: OnboardingIntro.bigSize,
                step: intro.step,
                ink: AppColor.Text.primary
            )
            .scaleEffect(intro.isSplash ? 1 : scale, anchor: .topLeading)
            .padding(intro.isSplash ? EdgeInsets() : OnboardingIntro.cornerInset)
            .frame(
                maxWidth: .infinity, maxHeight: .infinity,
                alignment: intro.isSplash ? .center : .topLeading
            )
        }
        .contentShape(Rectangle())
        .onTapGesture { OnboardingIntroPlayer.moveToCorner($intro) }
        // While it moves away, touches go to the genres underneath.
        .allowsHitTesting(intro.isSplash)
        .accessibilityAction(named: Text("Skip")) { OnboardingIntroPlayer.moveToCorner($intro) }
    }
}

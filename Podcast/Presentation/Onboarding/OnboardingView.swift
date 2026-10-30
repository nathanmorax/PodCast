//
//  OnboardingView.swift
//  Podcast
//

import SwiftUI

/// "What do you like to listen to?" — one screen on the app's cream paper
/// (near-black in dark mode), the question in tall capitals. Genres are
/// raised pills; picked ones turn deep green with a check. Shown on first launch and from Home's "Edit".
///
/// On first launch it opens with the "Tell me more" splash (OnboardingSplash):
/// the phrase forms over the launch color, then settles in the top-left corner.
struct OnboardingView: View {

    @Environment(\.interestsManager) private var interests
    @State private var model: OnboardingViewModel
    @State private var intro: OnboardingIntro
    /// The small phrase in the corner: first launch only, not from "Edit".
    private let showsMark: Bool
    /// The question's size, growing with the text size.
    @ScaledMetric(relativeTo: .largeTitle) private var questionSize: CGFloat = 52

    init(selectedIDs: [String] = [], playsIntro: Bool = false) {
        _model = State(initialValue: OnboardingViewModel(selectedIDs: selectedIDs))
        let plays = playsIntro && !UIAccessibility.isReduceMotionEnabled
        _intro = State(initialValue: OnboardingIntro(plays: plays))
        showsMark = playsIntro
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.screenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if showsMark {
                        // Swapped in when the big phrase lands here.
                        TellMeMoreMark(size: OnboardingIntro.smallSize, ink: AppColor.Text.primary)
                            .opacity(intro.step == .settled ? 1 : 0)
                            .padding(.bottom, 20)
                    }

                    Group {
                        Text("What do you like to listen to?")
                            .font(.system(size: questionSize, weight: .bold).width(.compressed))
                            .textCase(.uppercase)
                            .minimumScaleFactor(0.6)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Text("Pick at least one.")
                            .font(AppFont.body)
                            .opacity(0.85)

                        FlowLayout(spacing: 10, lineSpacing: 10) {
                            ForEach(model.genres, id: \.id) { genre in
                                pill(genre)
                            }
                        }
                        .padding(.top, 28)

                        chooseForMeButton
                            .padding(.top, 18)
                    }
                    .opacity(intro.showsContent ? 1 : 0)
                    .offset(y: intro.showsContent ? 0 : 16)
                }
                .foregroundStyle(AppColor.Text.primary)
                .padding(.horizontal, 20)
                .padding(.top, showsMark ? OnboardingIntro.cornerInset.top : 56)
                .padding(.bottom, 120) // room for the button
            }
            .scrollIndicators(.hidden)

            continueButton
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .opacity(intro.showsContent ? 1 : 0)

            // First launch: the phrase forms here, then moves to the corner.
            if intro.step < .settled {
                OnboardingSplashLayer(intro: $intro)
            }
        }
        .task { await OnboardingIntroPlayer.play($intro) }
        // Only when reopened from Home: a way out without changes.
        .overlay(alignment: .topTrailing) {
            if interests.isEditing { cancelButton }
        }
    }

    // MARK: - Pieces

    private func pill(_ genre: Genre) -> some View {
        let isOn = model.isSelected(genre)
        return Button {
            withAnimation(AppAnimation.selection) { model.toggle(genre) }
        } label: {
            HStack(spacing: 6) {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(genre.name)
                    .font(AppFont.button)
            }
            .foregroundStyle(isOn ? AppColor.screenBackground : AppColor.accentInk)
            .padding(.horizontal, isOn ? 16 : 20)
            .frame(height: 48)
            .background(Capsule().fill(isOn ? AppColor.accentInk : AppColor.Surface.raised))
            .overlay {
                if !isOn { Capsule().strokeBorder(AppColor.Text.primary.opacity(0.12), lineWidth: 1) }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var continueButton: some View {
        Button {
            withAnimation(AppAnimation.onboarding) { model.finish(into: interests) }
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(AppFont.button)
                Text(model.selectedIDs.count, format: .number)
                    .font(AppFont.captionStrong)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(minWidth: 24, minHeight: 24)
                    .background(Circle().fill(AppColor.Text.onPastel.opacity(0.12)))
            }
            // Ink on mustard: the one filled button on the page.
            .foregroundStyle(AppColor.Text.onPastel)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(AppColor.Accent.soft))
        }
        .buttonStyle(.plain)
        .opacity(model.canContinue ? 1 : 0.55)
        .disabled(!model.canContinue)
        .animation(AppAnimation.selection, value: model.selectedIDs.count)
        .accessibilityValue(Text("\(model.selectedIDs.count) selected"))
    }

    /// For people who don't want to think about it: the popular genres,
    /// which they can still change before continuing.
    private var chooseForMeButton: some View {
        Button {
            withAnimation(AppAnimation.selection) { model.chooseForMe() }
        } label: {
            Label("Choose for me", systemImage: "sparkles")
                .font(AppFont.label)
                .foregroundStyle(AppColor.Accent.strong)
                .underline()
        }
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button("Cancel") {
            withAnimation(AppAnimation.onboarding) { model.cancel(into: interests) }
        }
        .font(AppFont.label)
        .foregroundStyle(AppColor.Text.secondary)
        .padding(.horizontal, 20)
        .frame(minHeight: 44)
    }
}

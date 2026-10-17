//
//  OnboardingView.swift
//  Podcast
//

import SwiftUI

/// "What do you like to listen to?" — one screen, all lavender (the app's
/// brand color). Genres are white pills; picked ones turn deep lavender with
/// a check. Shown on first launch and from Home's "Edit".
struct OnboardingView: View {

    @Environment(\.interestsManager) private var interests
    @State private var model: OnboardingViewModel

    init(selectedIDs: [String] = []) {
        _model = State(initialValue: OnboardingViewModel(selectedIDs: selectedIDs))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.lavender
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you like to listen to?")
                        .font(.system(size: 34, weight: .heavy))
                        .tracking(-0.7)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("Pick 3 or more.")
                        .font(.system(size: 16))
                        .opacity(0.85)

                    FlowLayout(spacing: 10, lineSpacing: 10) {
                        ForEach(model.genres, id: \.id) { genre in
                            pill(genre)
                        }
                    }
                    .padding(.top, 28)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 120) // room for the button
            }
            .scrollIndicators(.hidden)

            continueButton
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .overlay(alignment: .topTrailing) { skipButton }
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
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(isOn ? Color.white : AppColor.lavenderInk)
            .padding(.horizontal, isOn ? 16 : 20)
            .frame(height: 48)
            .background(Capsule().fill(isOn ? AppColor.lavenderInk : Color.white.opacity(0.9)))
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
                    .font(.system(size: 17, weight: .semibold))
                Text(model.selectedIDs.count, format: .number)
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(minWidth: 24, minHeight: 24)
                    .background(Circle().fill(AppColor.lavender.opacity(0.25)))
            }
            .foregroundStyle(AppColor.lavenderInk)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(.white))
        }
        .buttonStyle(.plain)
        .opacity(model.canContinue ? 1 : 0.55)
        .disabled(!model.canContinue)
        .animation(AppAnimation.selection, value: model.selectedIDs.count)
        .accessibilityValue(Text("\(model.selectedIDs.count) selected"))
    }

    private var skipButton: some View {
        Button("Skip") {
            withAnimation(AppAnimation.onboarding) { model.skip(into: interests) }
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 20)
        .frame(minHeight: 44)
    }
}

#Preview {
    OnboardingView(selectedIDs: ["1303", "1533"])
        .environment(\.interestsManager, .preview)
}

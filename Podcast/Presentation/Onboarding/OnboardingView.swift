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
                        .font(AppFont.display)
                        .tracking(-0.7)
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
                    .font(AppFont.button)
                Text(model.selectedIDs.count, format: .number)
                    .font(AppFont.captionStrong)
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

    /// For people who don't want to think about it: the popular genres,
    /// which they can still change before continuing.
    private var chooseForMeButton: some View {
        Button {
            withAnimation(AppAnimation.selection) { model.chooseForMe() }
        } label: {
            Label("Choose for me", systemImage: "sparkles")
                .font(AppFont.label)
                .foregroundStyle(.white)
                .underline()
        }
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button("Cancel") {
            withAnimation(AppAnimation.onboarding) { model.cancel(into: interests) }
        }
        .font(AppFont.label)
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 20)
        .frame(minHeight: 44)
    }
}

#Preview {
    OnboardingView(selectedIDs: ["1303", "1533"])
        .environment(\.interestsManager, .preview)
}

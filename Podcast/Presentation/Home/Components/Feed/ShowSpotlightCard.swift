//
//  ShowSpotlightCard.swift
//  Podcast
//

import SwiftUI

/// A show you don't follow yet, in Home's feed (like a magazine's
/// "trending" profile): its cover, the genre, its name in tall capitals and
/// a line from its latest episode in quotes; under them why it's here and
/// Follow / share. The cover and name open the show.
struct ShowSpotlightCard: View {

    let item: PodcastEpisode
    let isFollowing: Bool
    let onOpenPodcast: () -> Void
    let onToggleFollow: () -> Void

    private var quote: String {
        let notes = EpisodeNotes(item.episode.description)
        return notes.quote ?? notes.rest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpenPodcast) {
                HStack(alignment: .top, spacing: 16) {
                    Color.clear
                        .frame(width: 128, height: 128)
                        .overlay { ZoomSourceImage(podcast: item.podcast, cornerRadius: 0) }
                        .clipped()
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show to follow")
                            .font(.caption.weight(.bold))
                        if let genre = item.podcast.genreName {
                            Text(genre)
                                .font(.caption2.weight(.bold))
                                .textCase(.uppercase)
                                .tracking(1)
                                .foregroundStyle(AppColor.Text.secondary)
                                .padding(.top, 4)
                        }
                        Text(item.showName)
                            .font(AppFont.feedTitle)
                            .textCase(.uppercase)
                            .lineLimit(2)
                        if !quote.isEmpty {
                            Text("“\(quote)”")
                                .font(.footnote)
                                .lineLimit(4)
                                .padding(.top, 2)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the podcast")

            HStack(spacing: 4) {
                if let genre = item.podcast.genreName {
                    Text("Because you like \(genre)")
                        .font(.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)

                Button(action: onToggleFollow) {
                    Label(isFollowing ? "Following" : "Follow", systemImage: isFollowing ? "checkmark" : "plus")
                        .font(.subheadline.weight(.bold))
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 36)
                        .overlay { Capsule().strokeBorder(AppColor.Text.primary, lineWidth: 1) }
                        .frame(minHeight: 44)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: isFollowing) { _, following in following }

                if let url = URL(string: "https://podcasts.apple.com/podcast/id\(item.podcast.trackId)") {
                    ShareLink(item: url, subject: Text(item.showName)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share")
                }
            }
        }
        .foregroundStyle(AppColor.Text.primary)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.paper)
    }
}

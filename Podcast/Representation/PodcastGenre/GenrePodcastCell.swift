//
//  GenrePodcastCell.swift
//  Podcast
//
//  Created by Satori Tech 341 on 25/02/26.
//
import SwiftUI

struct GenrePodcastCell: View {
    let genre: Genre
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(genre.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 130)
        .cornerRadius(8)
    }
}

#if DEBUG
extension Genre {
    static let mock = Genre(
        id: "",
        name: "Horror"
    )
}
#endif

#Preview(traits: .sizeThatFitsLayout) {
    GenrePodcastCell(genre: .mock)
        .padding()
}


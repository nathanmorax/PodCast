//
//  GenrePodcastCell.swift
//  Podcast
//
//  Created by Jesus Mora on 25/02/26.
//
import SwiftUI

enum AppColor {
    static let limeGreen     = Color("limeGreen")
    static let dustyRose     = Color("dustyRose")
    static let coralRed      = Color("colarRed")
    static let slateGray     = Color("slateGray")
    static let warmOrange    = Color("warmOrange")
    static let paleYellow    = Color("paleYellow")
    static let dustyBlue     = Color("dustyBlue")
    static let oliveGreen    = Color("oliveGreen")
    static let burntOrange   = Color("burntOrange")
    static let charcoalBrown = Color("charcoalBrown")

    static let palette: [Color] = [
        limeGreen,
        dustyRose,
        coralRed,
        slateGray,
        warmOrange,
        paleYellow,
        dustyBlue,
        oliveGreen,
        burntOrange,
        charcoalBrown
    ]
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}

struct GenrePodcastCell: View {
    let genre: Genre
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(genre.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color(for: index))
        )
    }
    
    private func color(for index: Int) -> Color {
        let palette = AppColor.palette
        
        var newIndex = index % palette.count
        
        if index > 0 && newIndex == (index - 1) % palette.count {
            newIndex = (newIndex + 1) % palette.count
        }
        
        return palette[newIndex]
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
    GenrePodcastCell(genre: .mock, index: 0)
        .padding()
}


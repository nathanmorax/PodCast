//
//  GenrePodcastCell.swift
//  Podcast
//
//  Created by Jesus Mora on 25/02/26.
//
import SwiftUI

enum AppColor {
    
    // MARK: - Raw palette
    
    static let limeGreen     = Color("limeGreen")
    static let dustyRose     = Color("dustyRose")
    static let coralRed      = Color("coralRed")    // OJO: tu asset tiene typo "colarRed"
    static let slateGray     = Color("slateGray")
    static let warmOrange    = Color("warmOrange")
    static let paleYellow    = Color("paleYellow")
    static let dustyBlue     = Color("dustyBlue")
    static let oliveGreen    = Color("oliveGreen")
    static let burntOrange   = Color("burntOrange")
    static let charcoalBrown = Color("charcoalBrown")
    static let lavender      = Color("lavender")
    static let background    = Color("background")
    
    // MARK: - Semantic roles
    
    enum Brand {
        static let primary   = AppColor.background
        static let secondary = AppColor.paleYellow
    }
    
    enum Status {
        static let success  = AppColor.oliveGreen
        static let warning  = AppColor.burntOrange
        static let critical = AppColor.coralRed
        static let info     = AppColor.dustyBlue
    }
    
    enum Surface {
        static let primary   = AppColor.paleYellow
        static let secondary = AppColor.dustyRose
        static let elevated  = Color.white
    }
    
    enum Text {
        static let primary   = AppColor.charcoalBrown
        static let secondary = AppColor.slateGray
        static let inverse   = Color.white
    }
    
    static let palette: [Color] = [
        limeGreen, dustyRose, coralRed, slateGray,
        warmOrange, paleYellow, dustyBlue, oliveGreen,
        burntOrange, charcoalBrown, lavender
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

//#Preview(traits: .sizeThatFitsLayout) {
//    GenrePodcastCell(genre: .mock, index: 0)
//        .padding()
//}


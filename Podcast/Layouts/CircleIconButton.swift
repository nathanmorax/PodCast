//
//  CircleIconButton.swift
//  Podcast
//
//  Created by Jonathan Mora on 11/05/26.
//

import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    var isHighlighted: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(isHighlighted ? .white : .black)
                .frame(width: 44, height: 44)
                .background(
                    isHighlighted
                        ? Color(AppColor.lavender)
                        : Color(.systemGray6),
                    in: Circle()
                )
                .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        }
    }
}

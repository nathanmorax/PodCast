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
                .foregroundStyle(isHighlighted ? AppColor.Text.onPastel : AppColor.Text.primary)
                .frame(width: 44, height: 44)
                .background(
                    isHighlighted
                        ? Color(AppColor.accent)
                        : Color(.systemGray6),
                    in: Circle()
                )
                .animation(AppAnimation.stateChange, value: isHighlighted)
        }
    }
}

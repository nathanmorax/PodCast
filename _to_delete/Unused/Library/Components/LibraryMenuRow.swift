//
//  LibraryMenuRow.swift
//  Podcast
//

import SwiftUI

struct LibraryMenuRow: View {
    let item: LibraryMenuItem

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(AppColor.Accent.strong)
                .frame(width: 28)

            Text(item.title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

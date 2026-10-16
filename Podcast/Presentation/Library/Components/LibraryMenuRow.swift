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
                .foregroundStyle(Color(.black))
                .frame(width: 28)

            Text(item.title)
                .font(.system(size: 17))
                .foregroundStyle(.black)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray.opacity(0.6))
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

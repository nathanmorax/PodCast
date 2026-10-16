//
//  WaveformIcon.swift
//  Podcast
//

import SwiftUI

struct WaveformIcon: View {
    @State private var animate = false
    
    private let heights: [CGFloat] = [0.4, 1.0, 0.6, 0.9, 0.5]
    private let delays: [Double]   = [0.0, 0.15, 0.05, 0.20, 0.10]
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 3, height: 16)
                    .scaleEffect(
                        y: animate ? heights[i] : 0.35,
                        anchor: .center
                    )
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(delays[i]),
                        value: animate
                    )
            }
        }
        .frame(width: 42, height: 42)
        .background(Color.green.opacity(0.1), in: Circle())
        .onAppear { animate = true }
    }
}

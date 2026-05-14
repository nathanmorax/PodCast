//
//
//  WaveformBars.swift
//  Podcast
//

import SwiftUI

struct WaveformBars: View {
    
    /// Progreso actual de reproducción (0.0 a 1.0)
    let progress: Float
    
    /// Cantidad de barras a renderizar
    let barCount: Int
    
    /// Callback opcional para hacer seek al tocar una barra
    let onSeek: ((Float) -> Void)?
    
    /// Alturas de cada barra (estables entre renders)
    private let heights: [CGFloat]
    
    init(progress: Float,
         barCount: Int = 60,
         onSeek: ((Float) -> Void)? = nil) {
        self.progress = progress
        self.barCount = barCount
        self.onSeek = onSeek
        
        var generator = SeededGenerator(seed: 42)
        self.heights = (0..<barCount).map { _ in
            CGFloat.random(in: 0.2...1.0, using: &generator)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(barColor(at: index))
                        .frame(height: geometry.size.height * heights[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(seekGesture(width: geometry.size.width))
        }
    }
    
    // MARK: - Helpers
    
    private func barColor(at index: Int) -> Color {
        let barPosition = Float(index) / Float(barCount)
        return barPosition <= progress
            ? AppColor.charcoalBrown
            : AppColor.slateGray.opacity(0.4)
    }
    
    private func seekGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                guard let onSeek else { return }
                let percentage = Float(value.location.x / width)
                onSeek(max(0, min(1, percentage)))
            }
    }
}

// MARK: - Random generator con seed

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        Text("0%")
        WaveformBars(progress: 0.0)
            .frame(height: 40)
        
        Text("30%")
        WaveformBars(progress: 0.3)
            .frame(height: 40)
        
        Text("70%")
        WaveformBars(progress: 0.7)
            .frame(height: 40)
        
        Text("100%")
        WaveformBars(progress: 1.0)
            .frame(height: 40)
    }
    .padding()
}

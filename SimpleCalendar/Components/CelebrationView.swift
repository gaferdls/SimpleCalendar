//
//  CelebrationView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/20/25.
//

import SwiftUI

struct CelebrationView: View {
    // A binding to the optional DayEntry that triggers the animation.
    @Binding var trigger: DayEntry?
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isAnimating {
                    ForEach(0..<150) { _ in
                        ParticleView(size: geometry.size)
                    }
                }
            }
        }
        .onChange(of: trigger) { _, newValue in
            // When the trigger gets a value, start the animation.
            guard newValue != nil else { return }
            isAnimating = true
            // After a delay, turn off the animation and reset the trigger.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isAnimating = false
                trigger = nil
            }
        }
    }
}

// A helper view for a single particle in the animation.
struct ParticleView: View {
    let size: CGSize
    @State private var isAnimating = false
    
    // Private properties to randomize each particle's appearance and movement.
    private let colors: [Color] = [.blue, .green, .red, .orange, .purple, .yellow]
    private let startX: CGFloat
    private let startY: CGFloat
    private let endY: CGFloat
    private let scale: CGFloat
    private let duration: Double
    private let delay: Double

    init(size: CGSize) {
        self.size = size
        self.startX = .random(in: 0...size.width)
        self.startY = size.height + 50
        self.endY = .random(in: -50...size.height/2)
        self.scale = .random(in: 0.5...1.5)
        self.duration = .random(in: 0.8...1.5)
        self.delay = .random(in: 0...0.3)
    }

    var body: some View {
        Circle()
            .fill(colors.randomElement()!)
            .frame(width: 15, height: 15)
            .scaleEffect(isAnimating ? scale : 0)
            .position(x: startX, y: isAnimating ? endY : startY)
            .animation(.easeOut(duration: duration).delay(delay), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

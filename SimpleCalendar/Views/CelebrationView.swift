import SwiftUI

struct CelebrationView: View {
    @Binding var trigger: Task?

    @State private var particles: [Particle] = []
    @State private var isVisible = false

    var body: some View {
        ZStack {
            if isVisible {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .scaleEffect(particle.scale)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
        }
        .onChange(of: trigger) { old, new in
            if new != nil {
                isVisible = true
                createParticles()

                withAnimation(.easeInOut(duration: 1.5)) {
                    updateParticles()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isVisible = false
                    trigger = nil
                }
            }
        }
    }

    private func createParticles() {
        particles = (0...100).map { _ in
            let size = CGFloat.random(in: 5...20)
            let x = CGFloat.random(in: -50...UIScreen.main.bounds.width + 50)
            let y = UIScreen.main.bounds.height + size

            return Particle(
                size: size,
                position: CGPoint(x: x, y: y),
                color: Color(hue: .random(in: 0...1), saturation: 1, brightness: 1),
                scale: 1.0,
                opacity: 1.0
            )
        }
    }

    private func updateParticles() {
        for i in particles.indices {
            let newX = particles[i].position.x + .random(in: -150...150)
            let newY = particles[i].position.y - .random(in: 400...800)

            particles[i].position = CGPoint(x: newX, y: newY)
            particles[i].scale = .random(in: 0.5...2.0)
            particles[i].opacity = 0
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var size: CGFloat
    var position: CGPoint
    var color: Color
    var scale: CGFloat
    var opacity: Double
}

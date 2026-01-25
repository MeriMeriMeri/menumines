import SwiftUI

struct ConfettiView: View {
    let isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var animationPhase: CGFloat = 0

    private let particleCount = 50
    private let colors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue, .green]

    private var reduceMotionEnabled: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if reduceMotionEnabled {
                    reducedMotionCelebration
                } else {
                    ForEach(particles) { particle in
                        ConfettiParticleView(particle: particle, phase: animationPhase)
                    }
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startCelebration(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var reducedMotionCelebration: some View {
        Text("🎉")
            .font(.system(size: 48))
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.5)
            .animation(.easeOut(duration: 0.3), value: isActive)
    }

    private func initializeParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .yellow,
                startX: CGFloat.random(in: 0...size.width),
                startY: CGFloat.random(in: -50...(-10)),
                endY: size.height + 50,
                horizontalDrift: CGFloat.random(in: -30...30),
                rotation: CGFloat.random(in: 0...360),
                rotationSpeed: CGFloat.random(in: -360...360),
                delay: CGFloat.random(in: 0...0.5),
                size: CGFloat.random(in: 6...12)
            )
        }
    }

    private func startCelebration(in size: CGSize) {
        initializeParticles(in: size)
        animationPhase = 0

        withAnimation(.linear(duration: 1.5)) {
            animationPhase = 1
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let horizontalDrift: CGFloat
    let rotation: CGFloat
    let rotationSpeed: CGFloat
    let delay: CGFloat
    let size: CGFloat
}

private struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let phase: CGFloat

    private var adjustedPhase: CGFloat {
        max(0, min(1, (phase - particle.delay) / (1 - particle.delay)))
    }

    private var currentY: CGFloat {
        particle.startY + (particle.endY - particle.startY) * adjustedPhase
    }

    private var currentX: CGFloat {
        particle.startX + particle.horizontalDrift * sin(adjustedPhase * .pi * 2)
    }

    private var currentRotation: CGFloat {
        particle.rotation + particle.rotationSpeed * adjustedPhase
    }

    private var opacity: CGFloat {
        switch adjustedPhase {
        case ..<0.1: adjustedPhase * 10
        case 0.8...: (1 - adjustedPhase) * 5
        default: 1
        }
    }

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(currentRotation))
            .position(x: currentX, y: currentY)
            .opacity(opacity)
    }
}

#Preview("Confetti Active") {
    ZStack {
        Color.gray.opacity(0.3)
        ConfettiView(isActive: true)
    }
    .frame(width: 300, height: 400)
}

#Preview("Confetti Inactive") {
    ZStack {
        Color.gray.opacity(0.3)
        ConfettiView(isActive: false)
    }
    .frame(width: 300, height: 400)
}

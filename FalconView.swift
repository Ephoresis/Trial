import SwiftUI

struct FalconView: View {
    @State private var flap = false

    var body: some View {
        ZStack {
            // Corpo
            Ellipse()
                .fill(Color.gray)
                .frame(width: 40, height: 25)

            // Cabeça
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .offset(x: 20, y: -5)

            // Bico
            Triangle()
                .fill(Color.yellow)
                .frame(width: 10, height: 10)
                .offset(x: 30, y: -5)

            // Asa (animada)
            WingShape()
                .fill(Color.gray.opacity(0.9))
                .frame(width: 50, height: 30)
                .offset(x: -5, y: flap ? -10 : 5)
                .animation(
                    Animation.easeInOut(duration: 0.25)
                        .repeatForever(autoreverses: true),
                    value: flap
                )
        }
        .onAppear {
            flap.toggle()
        }
    }
}

// Formas auxiliares

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

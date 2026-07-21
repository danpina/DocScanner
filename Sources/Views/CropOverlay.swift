import SwiftUI

struct CropOverlay: View {
    @Binding var corners: [CGPoint]
    let containerSize: CGSize

    private var quadPath: Path {
        Path { path in
            guard corners.count == 4 else { return }
            path.move(to: corners[0])
            path.addLine(to: corners[1])
            path.addLine(to: corners[2])
            path.addLine(to: corners[3])
            path.closeSubpath()
        }
    }

    var body: some View {
        ZStack {
            quadPath.fill(Color.yellow.opacity(0.15))
            quadPath.stroke(Color.yellow, lineWidth: 2)

            ForEach(corners.indices, id: \.self) { index in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 24, height: 24)
                    .position(corners[index])
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                corners[index] = clamp(value.location)
                            }
                    )
            }
        }
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), containerSize.width),
            y: min(max(point.y, 0), containerSize.height)
        )
    }
}

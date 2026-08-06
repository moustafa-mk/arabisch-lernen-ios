import SwiftUI

struct LetterStrokeShape: Shape {
    let strokePaths: [StrokePath]

    func path(in rect: CGRect) -> Path {
        var result = Path()
        for strokePath in strokePaths {
            guard let first = strokePath.points.first else {
                continue
            }
            result.move(to: point(first, in: rect))
            for strokePoint in strokePath.points.dropFirst() {
                result.addLine(to: point(strokePoint, in: rect))
            }
        }
        return result
    }

    private func point(_ point: StrokePoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + rect.width * point.x,
            y: rect.minY + rect.height * point.y
        )
    }
}

struct LetterStrokeGuide: View {
    let letter: LetterContent
    let animate: Bool

    @State private var progress = 0.0

    var body: some View {
        LetterStrokeShape(strokePaths: letter.strokePaths)
            .trim(from: 0, to: progress)
            .stroke(
                AppColor.terracotta,
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )
            .onAppear {
                if animate {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        progress = 1
                    }
                } else {
                    progress = 1
                }
            }
            .onChange(of: animate) { _, newValue in
                progress = newValue ? 0 : 1
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        progress = 1
                    }
                }
            }
            .accessibilityHidden(true)
    }
}

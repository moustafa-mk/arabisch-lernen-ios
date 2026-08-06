import PencilKit
import SwiftUI

struct WritingCanvas: UIViewRepresentable {
    let canvasView: PKCanvasView
    let accessibilityLabel: String

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: UIColor(AppColor.teal), width: 8)
        canvasView.accessibilityLabel = accessibilityLabel
        canvasView.accessibilityHint = "Schreibe mit dem Finger oder Apple Pencil."
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.accessibilityLabel = accessibilityLabel
    }
}

import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.allowsFingerDrawing = true
        canvasView.backgroundColor = UIColor.systemBackground
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawingPolicy = .anyInput
    }
}

struct CanvasContainerView: View {
    @State private var detectedRects: [CGRect] = []
    @State private var canvasView = PKCanvasView()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Drawing canvas
            CanvasView(canvasView: $canvasView)
                .edgesIgnoringSafeArea(.all)

            // 🔵 Overlay rectangles on top of the canvas
            ForEach(detectedRects, id: \.self) { rect in
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .background(Color.blue.opacity(0.2))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }

            // Bottom control bar
            HStack {
                Button(action: {
                    canvasView.drawing = PKDrawing()
                }) {
                    Label("Clear", systemImage: "trash")
                        .padding()
                }

                Spacer()

                    Button(action: {
                        print("🟡 Generate tapped")

                        if let image = canvasView.snapshotImage() {
                            print("📸 Snapshot captured")

                            let analyzer = VisionAnalysisService()
                            analyzer.detectRectangles(in: image) { rectangles in
                                print("📐 Detected \(rectangles.count) rectangle(s)")

                                DispatchQueue.main.async {
                                    let canvasSize = canvasView.bounds.size

                                    let convertedRects = rectangles.map { rect -> CGRect in
                                        let boundingBox = rect.boundingBox
                                        let width = boundingBox.width * canvasSize.width
                                        let height = boundingBox.height * canvasSize.height
                                        let x = boundingBox.minX * canvasSize.width
                                        let y = (1 - boundingBox.maxY) * canvasSize.height
                                        return CGRect(x: x, y: y, width: width, height: height)
                                    }

                                    self.detectedRects = convertedRects
                                }
                            }
                        }
                    }) {
                    Label("Generate", systemImage: "wand.and.stars")
                        .padding()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
        .navigationTitle("Sketch")
    }
}

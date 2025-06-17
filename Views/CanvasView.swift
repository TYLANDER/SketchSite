import SwiftUI
import PencilKit

// MARK: - ChatGPTService Stub


// MARK: - CanvasView for PencilKit Drawing
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

// MARK: - Container View with VisionKit Analysis
struct CanvasContainerView: View {
    @State private var generatedCode: String? = nil
    @State private var showCodePreview = false
    @State private var detectedRects: [CGRect] = []
    @State private var canvasView = PKCanvasView()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Drawing canvas
            CanvasView(canvasView: $canvasView)
                .edgesIgnoringSafeArea(.all)

            // Rectangle overlays
            ForEach(detectedRects, id: \.self) { rect in
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .background(Color.blue.opacity(0.2))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }

            // Bottom toolbar
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
                    self.showCodePreview = false // Ensure sheet resets

                    if let image = canvasView.snapshotImage() {
                        print("📸 Snapshot captured")

                        let analyzer = VisionAnalysisService()
                        analyzer.detectRectangles(in: image) { rectangles in
                            DispatchQueue.main.async {
                                print("📐 Detected \(rectangles.count) rectangle(s)")

                                let canvasSize = canvasView.bounds.size
                                let convertedRects = rectangles.map { rect -> CGRect in
                                    let bb = rect.boundingBox
                                    let width = bb.width * canvasSize.width
                                    let height = bb.height * canvasSize.height
                                    let x = bb.minX * canvasSize.width
                                    let y = (1 - bb.maxY) * canvasSize.height
                                    return CGRect(x: x, y: y, width: width, height: height)
                                }

                                self.detectedRects = convertedRects

                                let description = LayoutDescriptor.describe(rects: convertedRects, canvasSize: canvasSize)
                                print("📝 Layout Description:\n\(description)")

                                let prompt = """
                                Generate HTML and CSS code for the following layout:
                                \(description)
                                """

                                ChatGPTService.shared.generateCode(prompt: prompt) { result in
                                    switch result {
                                    case .success(let code):
                                        print("🧠 Generated Code:\n\(code)")
                                        self.generatedCode = code
                                        self.showCodePreview = true
                                    case .failure(let error):
                                        print("❌ Error: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    }
                }) {
                    Label("Generate", systemImage: "wand.and.stars")
                        .padding()
                }

                if generatedCode != nil {
                    Button(action: {
                        self.showCodePreview = true
                    }) {
                        Label("Show Code", systemImage: "doc.plaintext")
                            .padding()
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
        .sheet(isPresented: $showCodePreview) {
            if let code = generatedCode {
                AnimatedCodePreview(code: code)
            }
        }
        .navigationTitle("Sketch")
    }
}

struct AnimatedCodePreview: View {
    let code: String

    var body: some View {
        VStack {
            Spacer()
            CodePreviewView(code: code)
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: code)
        }
    }
}

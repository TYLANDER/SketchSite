import SwiftUI
import PencilKit
import PhotosUI

/// A UIViewRepresentable wrapper for PKCanvasView, enabling PencilKit drawing in SwiftUI.
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Leave blank — all state is managed by PKCanvasView itself
    }
}

/// The main container view for the sketching experience, with a full-screen canvas and overlay toolbars.
struct CanvasContainerView: View {
    @State private var canvasView = PKCanvasView()
    @State private var undoStack: [PKDrawing] = []
    @State private var redoStack: [PKDrawing] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    
    // Detection and generation state
    @State private var detectedComponents: [DetectedComponent] = []
    @State private var isAnalyzing = false
    @State private var analysisError: String? = nil
    @State private var showErrorAlert = false
    
    private let visionService = VisionAnalysisService()
    
    var body: some View {
        ZStack {
            // Full-screen canvas background
            CanvasView(canvasView: $canvasView)
                .ignoresSafeArea(.all)
                .onChange(of: canvasView.drawing) { newDrawing in
                    undoStack.append(newDrawing)
                    redoStack.removeAll()
                }
            
            // Top header overlay
            VStack {
                topBar
                Spacer()
            }
            .ignoresSafeArea(.all)
            
            // Bottom toolbar overlay
            VStack {
                Spacer()
                bottomToolbar
            }
            .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSource) { image in
                if let img = image {
                    selectedImage = img
                    // run VisionKit analysis here if needed
                }
                showImagePicker = false
            }
        }
        .alert("Analysis Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(analysisError ?? "Unknown error occurred")
        }
    }

    // MARK: - Top Header
    private var topBar: some View {
        VStack(spacing: 0) {
            // Status bar spacer
            Color.clear
                .frame(height: 50)
            
            HStack {
                Text("SketchSite")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Picker("Model", selection: .constant("gpt-4o")) {
                    Text("gpt-4o").tag("gpt-4o")
                    Text("gpt-3.5").tag("gpt-3.5")
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                }
                .disabled(undoStack.isEmpty)
                
                Button(action: clearCanvas) {
                    Image(systemName: "trash")
                        .font(.title2)
                }
                
                Button(action: redo) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title2)
                }
                .disabled(redoStack.isEmpty)
                
                Spacer()
                
                // Generate button with loading state
                Button(action: generateComponents) {
                    HStack(spacing: 4) {
                        if isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wand.and.rays")
                                .font(.title2)
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Generate")
                            .font(.caption)
                    }
                    .frame(minWidth: 80)
                }
                .disabled(isAnalyzing || canvasView.drawing.strokes.isEmpty)
                
                Spacer()
                
                Button(action: { pick(.camera) }) {
                    Image(systemName: "camera")
                        .font(.title2)
                }
                Button(action: { pick(.photoLibrary) }) {
                    Image(systemName: "photo")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Home indicator spacer
            Color.clear
                .frame(height: 35)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions
    private func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(canvasView.drawing)
        canvasView.drawing = last
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(canvasView.drawing)
        canvasView.drawing = next
    }

    private func clearCanvas() {
        undoStack.append(canvasView.drawing)
        canvasView.drawing = PKDrawing()
        redoStack.removeAll()
        // Clear detected components when canvas is cleared
        detectedComponents.removeAll()
    }

    private func pick(_ source: UIImagePickerController.SourceType) {
        imagePickerSource = source
        showImagePicker = true
    }
    
    // MARK: - Vision Analysis
    private func generateComponents() {
        guard !canvasView.drawing.strokes.isEmpty else { return }
        
        isAnalyzing = true
        analysisError = nil
        
        // Take snapshot of current canvas
        guard let canvasImage = canvasView.snapshotImage() else {
            analysisError = "Failed to capture canvas image"
            showErrorAlert = true
            isAnalyzing = false
            return
        }
        
        // Get canvas size for coordinate conversion
        let canvasSize = canvasView.bounds.size
        
        // Run Vision analysis
        visionService.detectLayoutAndAnnotations(in: canvasImage, canvasSize: canvasSize) { components in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                if components.isEmpty {
                    self.analysisError = "No UI components detected. Try drawing clearer rectangles or shapes."
                    self.showErrorAlert = true
                } else {
                    self.detectedComponents = components
                    print("✅ Detected \(components.count) components:")
                    for (idx, comp) in components.enumerated() {
                        print("  \(idx + 1). \(comp.type.description) at \(comp.rect)")
                    }
                }
            }
        }
    }
}

// NOTE: You can continue to add your detection overlays, code‐generation buttons, and sheets
// onto this structure as needed, but the core canvas + toolbars now use a single ZStack + overlay

#if DEBUG
struct CanvasContainerView_Previews: PreviewProvider {
    static var previews: some View {
        CanvasContainerView()
    }
}
#endif

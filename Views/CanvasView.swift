import SwiftUI
import PencilKit

// MARK: - ChatGPTService Stub


// MARK: - CanvasView for PencilKit Drawing
/// A UIViewRepresentable wrapper for PKCanvasView, enabling PencilKit drawing in SwiftUI.
struct CanvasView: UIViewRepresentable {
    /// The PKCanvasView instance to be managed.
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        // Configure the canvas for any input and finger drawing.
        canvasView.drawingPolicy = .anyInput
        canvasView.allowsFingerDrawing = true
        canvasView.backgroundColor = UIColor.systemBackground
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Ensure the drawing policy is always set.
        uiView.drawingPolicy = .anyInput
    }
}

// MARK: - Container View with VisionKit Analysis
/// The main container view for the sketching experience, including drawing, detection, and overlays.
struct CanvasContainerView: View {
    @State private var generatedCode: String? = nil
    @State private var showCodePreview = false
    @State private var detectedComponents: [DetectedComponent] = []
    @State private var canvasView = PKCanvasView()
    @State private var selectedComponentID: UUID? = nil
    @State private var showTypePicker = false
    @State private var typePickerSelection: UIComponentType? = nil
    @State private var undoStack: [PKDrawing] = []
    @State private var redoStack: [PKDrawing] = []
    @State private var showInspector = false
    @State private var browserPreviewPresented = false
    @State private var selectedModel: String = "gpt-4o"
    @State private var customPrompt: String = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Drawing canvas (truly full screen, under nav bar and safe areas)
                CanvasView(canvasView: $canvasView)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                    .onChange(of: canvasView.drawing) { newDrawing in
                        // Push to undo stack on drawing change
                        undoStack.append(newDrawing)
                        redoStack.removeAll()
                    }

                // Prominent title at the top, above the canvas
                VStack(spacing: 0) {
                    Text("SketchSite – Draw Your UI")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            VisualEffectBlur()
                                .edgesIgnoringSafeArea(.top)
                        )
                    Spacer()
                }
                .zIndex(2)

                // Rectangle overlays with inferred component type labels
                ForEach(Array(detectedComponents.enumerated()), id: \.(1)) { idx, comp in
                    ZStack {
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .background(Color.blue.opacity(0.2))
                            .frame(width: comp.rect.width, height: comp.rect.height)
                            .position(x: comp.rect.midX, y: comp.rect.midY)
                        // Show the inferred type above the rectangle
                        Text(autoName(for: comp, index: idx))
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(6)
                            .position(x: comp.rect.midX, y: comp.rect.minY - 10)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedComponentID = comp.id
                        showInspector = true
                    }
                    .accessibilityLabel("Component: \(comp.type.description)")
                    .accessibilityHint("Double tap to inspect and edit component.")
                }

                // Bottom toolbar for clearing, generating, undo/redo, and showing code
                VStack {
                    Spacer()
                    HStack(spacing: 24) {
                        Button(action: {
                            // Undo drawing
                            guard !undoStack.isEmpty else { return }
                            let last = undoStack.removeLast()
                            redoStack.append(canvasView.drawing)
                            canvasView.drawing = last
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.title2)
                                Text("Undo").font(.caption)
                            }.frame(minWidth: 60, minHeight: 44)
                        }
                        .accessibilityLabel("Undo")
                        .accessibilityHint("Undo the last drawing action.")
                        Button(action: {
                            // Redo drawing
                            guard !redoStack.isEmpty else { return }
                            let last = redoStack.removeLast()
                            undoStack.append(canvasView.drawing)
                            canvasView.drawing = last
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.forward")
                                    .font(.title2)
                                Text("Redo").font(.caption)
                            }.frame(minWidth: 60, minHeight: 44)
                        }
                        .accessibilityLabel("Redo")
                        .accessibilityHint("Redo the last undone drawing action.")
                        Button(action: {
                            // Clear the canvas drawing
                            canvasView.drawing = PKDrawing()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "trash").font(.title2)
                                Text("Clear").font(.caption)
                            }.frame(minWidth: 60, minHeight: 44)
                        }
                        .accessibilityLabel("Clear Canvas")
                        .accessibilityHint("Removes all drawings from the canvas.")
                        Spacer(minLength: 0)
                        Button(action: {
                            // Regenerate code from current detection (no new Vision analysis)
                            let description = LayoutDescriptor.describe(components: detectedComponents, canvasSize: canvasView.bounds.size)
                            let prompt = customPrompt.isEmpty ? "Generate HTML and CSS for the following UI layout composed of multiple elements. Each element is represented by its size and position relative to the canvas:\n\n\(description)" : customPrompt
                            ChatGPTService.shared.generateCode(prompt: prompt) { result in
                                switch result {
                                case .success(let code):
                                    self.generatedCode = code
                                    self.showCodePreview = true
                                case .failure(let error):
                                    print("❌ Error: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise").font(.title2)
                                Text("Regenerate").font(.caption)
                            }.frame(minWidth: 60, minHeight: 44)
                        }
                        .accessibilityLabel("Regenerate Code")
                        .accessibilityHint("Reruns code generation with current detection.")
                        Button(action: {
                            self.browserPreviewPresented = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "safari").font(.title2)
                                Text("Preview").font(.caption)
                            }.frame(minWidth: 60, minHeight: 44)
                        }
                        .accessibilityLabel("Browser Preview")
                        .accessibilityHint("Preview generated HTML/CSS in a browser.")
                        if generatedCode != nil {
                            Button(action: {
                                self.showCodePreview = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "doc.plaintext").font(.title2)
                                    Text("Show Code").font(.caption)
                                }.frame(minWidth: 60, minHeight: 44)
                            }
                            .accessibilityLabel("Show Generated Code")
                            .accessibilityHint("Displays the generated HTML and CSS code.")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(VisualEffectBlur().edgesIgnoringSafeArea(.bottom))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
                    .accessibilityElement(children: .contain)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .sheet(isPresented: $showInspector) {
                if let id = selectedComponentID, let idx = detectedComponents.firstIndex(where: { $0.id == id }) {
                    InspectorView(component: $detectedComponents[idx])
                }
            }
            .sheet(isPresented: $browserPreviewPresented) {
                if let code = generatedCode {
                    BrowserPreviewView(html: code)
                }
            }
            .sheet(isPresented: $showTypePicker) {
                NavigationView {
                    List {
                        ForEach(UIComponentType.allCases, id: \ .self) { type in
                            HStack {
                                Text(type.rawValue.capitalized)
                                Spacer()
                                if type == typePickerSelection {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let id = selectedComponentID, let idx = detectedComponents.firstIndex(where: { $0.id == id }) {
                                    let old = detectedComponents[idx]
                                    detectedComponents[idx] = DetectedComponent(
                                        rect: old.rect,
                                        type: .ui(type),
                                        label: old.label
                                    )
                                    typePickerSelection = type
                                    showTypePicker = false
                                }
                            }
                            .accessibilityLabel(type.rawValue.capitalized)
                            .accessibilityAddTraits(type == typePickerSelection ? .isSelected : [])
                        }
                    }
                    .navigationTitle("Select Component Type")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showTypePicker = false }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCodePreview) {
            // Show the generated code in a modal sheet
            if let code = generatedCode {
                AnimatedCodePreview(code: code)
            }
        }
    }

    // Helper for auto-naming
    private func autoName(for comp: DetectedComponent, index: Int) -> String {
        let base = comp.type.description.capitalized
        return "\(base) \(index + 1)"
    }
}

/// VisualEffectBlur for background blur (works on iOS 15+)
struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

/// Animated code preview sheet for displaying generated code.
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

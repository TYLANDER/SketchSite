import SwiftUI
import PencilKit
import PhotosUI

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
    @State private var selectedPromptTemplate: String = ""
    @State private var chatHistory: [(role: String, content: String)] = []
    @State private var followUpInput: String = ""
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Model selector and prompt template picker
                HStack {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model.capitalized)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 180)
                    Picker("Prompt Template", selection: $selectedPromptTemplate) {
                        ForEach(promptTemplates, id: \.self) { template in
                            Text(template)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 180)
                }
                .padding(.horizontal)
                .padding(.top, geometry.safeAreaInsets.top + 8)
                ZStack(alignment: .top) {
                    // If a photo is selected, show it as the background
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .edgesIgnoringSafeArea(.all)
                    }
                    // Drawing canvas (truly full screen, under nav bar and safe areas)
                    if selectedImage == nil {
                        CanvasView(canvasView: $canvasView)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .edgesIgnoringSafeArea(.all)
                            .onChange(of: canvasView.drawing) { newDrawing in
                                undoStack.append(newDrawing)
                                redoStack.removeAll()
                            }
                    }
                    // Rectangle overlays with inferred component type labels
                    ForEach(Array(detectedComponents.enumerated()), id: \.(1)) { idx, comp in
                        ZStack {
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 2)
                                .background(Color.blue.opacity(0.2))
                                .frame(width: comp.rect.width, height: comp.rect.height)
                                .position(x: comp.rect.midX, y: comp.rect.midY)
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
                            let prompt = selectedPromptTemplate.isEmpty ? "Generate HTML and CSS for the following UI layout composed of multiple elements. Each element is represented by its size and position relative to the canvas:\n\n\(description)" : selectedPromptTemplate
                            ChatGPTService.shared.generateCode(prompt: prompt, model: selectedModel, conversation: chatHistory) { result in
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
                        Button(action: {
                            imagePickerSource = .camera
                            showImagePicker = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "camera").font(.title2)
                                Text("Take Photo").font(.caption)
                            }.frame(minWidth: 60, minHeight: 44)
                        }
                        .accessibilityLabel("Take Photo")
                        .accessibilityHint("Take a photo of a sketch to analyze.")
                        Button(action: {
                            imagePickerSource = .photoLibrary
                            showImagePicker = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "photo").font(.title2)
                                Text("Upload Photo").font(.caption)
                            }.frame(minWidth: 60, minHeight: 44)
                        }
                        .accessibilityLabel("Upload Photo")
                        .accessibilityHint("Upload a photo of a sketch from your library.")
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: imagePickerSource) { image in
                    if let img = image {
                        selectedImage = img
                        // Run Vision analysis on the selected image
                        let analyzer = VisionAnalysisService()
                        let canvasSize = CGSize(width: img.size.width, height: img.size.height)
                        analyzer.detectLayoutAndAnnotations(in: img, canvasSize: canvasSize) { components in
                            DispatchQueue.main.async {
                                detectedComponents = components
                            }
                        }
                    }
                    showImagePicker = false
                }
            }
        }
        .sheet(isPresented: $showCodePreview) {
            if let code = generatedCode {
                VStack(spacing: 0) {
                    AnimatedCodePreview(code: code)
                    Divider()
                    // Follow-up chat UI
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Follow-up with AI").font(.headline)
                        ScrollView {
                            ForEach(Array(chatHistory.enumerated()), id: \.(0)) { idx, msg in
                                HStack(alignment: .top) {
                                    Text(msg.role.capitalized + ":").bold().foregroundColor(msg.role == "user" ? .blue : .primary)
                                    Text(msg.content).foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }.frame(maxHeight: 120)
                        HStack {
                            TextField("Ask a follow-up or clarify...", text: $followUpInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Send") {
                                let userMsg = followUpInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !userMsg.isEmpty else { return }
                                chatHistory.append((role: "user", content: userMsg))
                                followUpInput = ""
                                // Compose conversation for model
                                let messages = chatHistory.map { ["role": $0.role, "content": $0.content] }
                                ChatGPTService.shared.generateCode(prompt: userMsg, model: selectedModel, conversation: messages) { result in
                                    switch result {
                                    case .success(let reply):
                                        chatHistory.append((role: "assistant", content: reply))
                                    case .failure(let error):
                                        chatHistory.append((role: "assistant", content: "Error: \(error.localizedDescription)"))
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // Helper for auto-naming
    private func autoName(for comp: DetectedComponent, index: Int) -> String {
        let base = comp.type.description.capitalized
        return "\(base) \(index + 1)"
    }

    var availableModels: [String] {
        [
            "gpt-4o", "gpt-4", "gpt-3.5-turbo",
            "claude-3-opus", "claude-3-sonnet", "claude-3-haiku"
        ]
    }
    var promptTemplates: [String] {
        [
            "HTML/CSS (default)",
            "SwiftUI",
            "Tailwind CSS",
            "Material UI",
            "Bootstrap",
            "React JSX"
        ]
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

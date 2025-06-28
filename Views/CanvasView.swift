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
    @State private var isCodePreviewButtonVisible: Bool = true

    private var modelAndPromptPicker: some View {
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
        .padding(.top, 8) // geometry.safeAreaInsets.top will be added in body
    }

    private var mainCanvasStack: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                if selectedImage == nil {
                    CanvasView(canvasView: $canvasView)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onChange(of: canvasView.drawing) { newDrawing in
                            undoStack.append(newDrawing)
                            redoStack.removeAll()
                        }
                }
                ForEach(Array(detectedComponents.enumerated()), id: \.1) { idx, comp in
                    ComponentOverlayView(
                        comp: comp,
                        idx: idx,
                        isSelected: selectedComponentID == comp.id,
                        onTap: {
                            selectedComponentID = comp.id
                            showInspector = true
                        }
                    )
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("SketchSite")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 16)
            Spacer()
            Picker("Model", selection: $selectedModel) {
                ForEach(availableModels, id: \.self) { model in
                    Text(model.capitalized).tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 120)
            .padding(.trailing, 16)
            .background(
                Capsule()
                    .fill(Color(.systemBackground).opacity(0.7))
                    .shadow(radius: 2)
            )
        }
        .frame(height: 44)
        .padding(.top, 8)
        .background(Color.clear)
    }

    // Responsive, scrollable bottom toolbar (no Undo/Redo)
    private var responsiveBottomToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                // Removed Undo/Redo
                ToolbarButton(systemImage: "trash", label: "Clear") {
                    canvasView.drawing = PKDrawing()
                }
                ToolbarButton(systemImage: "arrow.clockwise", label: "Regenerate") {
                    let description = LayoutDescriptor.describe(components: detectedComponents, canvasSize: canvasView.bounds.size)
                    let prompt = selectedPromptTemplate.isEmpty ? "Generate HTML and CSS for the following UI layout composed of multiple elements. Each element is represented by its size and position relative to the canvas:\n\n\(description)" : selectedPromptTemplate
                    let chatHistoryDicts = self.chatHistoryDicts
                    ChatGPTService.shared.generateCode(prompt: prompt, model: selectedModel, conversation: chatHistoryDicts) { result in
                        switch result {
                        case .success(let code):
                            self.generatedCode = code
                            self.showCodePreview = true
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
                ToolbarButton(systemImage: "safari", label: "Preview") {
                    self.browserPreviewPresented = true
                }
                if generatedCode != nil {
                    ToolbarButton(systemImage: "doc.plaintext", label: "Show Code") {
                        self.showCodePreview = true
                    }
                }
                ToolbarButton(systemImage: "camera", label: "Take Photo") {
                    imagePickerSource = .camera
                    showImagePicker = true
                }
                ToolbarButton(systemImage: "photo", label: "Upload Photo") {
                    imagePickerSource = .photoLibrary
                    showImagePicker = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 0)
            .padding(.vertical, 10)
            .background(VisualEffectBlur().clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)))
            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
    }

    private var codePreviewFloatingButton: some View {
        Group {
            if generatedCode != nil {
                Button(action: { self.showCodePreview = true }) {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.accentColor))
                        .shadow(radius: 4)
                }
                .accessibilityLabel("Show Generated Code")
                .accessibilityHint("Displays the generated HTML and CSS code.")
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            ZStack {
                Color.black.ignoresSafeArea()
                mainCanvasStack
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                // Compact header pinned to very top
                VStack(spacing: 0) {
                    HStack {
                        Text("SketchSite")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Picker("Model", selection: $selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model.capitalized).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 110)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(Capsule().fill(Color(.systemBackground).opacity(0.85)))
                    }
                    .padding(.top, safeArea.top + 24)
                    .padding(.bottom, 0)
                    .padding(.horizontal, 10)
                    .background(Color(.systemBackground).opacity(0.95))
                    Spacer()
                }
                .edgesIgnoringSafeArea(.top)
                // Responsive bottom toolbar pinned to very bottom
                VStack {
                    Spacer()
                    responsiveBottomToolbar
                        .padding(.bottom, safeArea.bottom)
                }
                .edgesIgnoringSafeArea(.bottom)
                // Floating code preview button (bottom right, above toolbar)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        codePreviewFloatingButton
                            .padding(.bottom, safeArea.bottom + 70)
                            .padding(.trailing, 18)
                    }
                }
            }
            .onAppear {
                validatePickerSelections()
            }
            .sheet(isPresented: $showInspector) {
                inspectorSheetContent
            }
            .sheet(isPresented: $browserPreviewPresented) {
                browserPreviewSheetContent
            }
            .sheet(isPresented: $showTypePicker) {
                TypePickerSheetView(
                    isPresented: $showTypePicker,
                    typePickerSelection: $typePickerSelection,
                    detectedComponents: detectedComponents,
                    selectedComponentID: selectedComponentID,
                    onTypeSelected: { type in
                        if let id = selectedComponentID, let idx = detectedComponents.firstIndex(where: { $0.id == id }) {
                            let old = detectedComponents[idx]
                            detectedComponents[idx] = DetectedComponent(
                                rect: old.rect,
                                type: .ui(type),
                                label: old.label
                            )
                            typePickerSelection = type
                        }
                    }
                )
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
            .sheet(isPresented: $showCodePreview) {
                codePreviewSheetContent
            }
        }
    }

    // Helper for auto-naming
    private func autoName(for comp: DetectedComponent, index: Int) -> String {
        let base = comp.type.description.capitalized
        return "\(base) \(index + 1)"
    }

    // Helper to convert chatHistory to [[String: String]]
    private var chatHistoryDicts: [[String: String]] {
        chatHistory.map { ["role": $0.role, "content": $0.content] }
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

    // Extracted InspectorView sheet content
    private var inspectorSheetContent: some View {
        Group {
            if let id = selectedComponentID, let idx = detectedComponents.firstIndex(where: { $0.id == id }) {
                InspectorView(component: $detectedComponents[idx])
            } else {
                Text("No component selected")
            }
        }
    }

    // Extracted BrowserPreviewView sheet content
    private var browserPreviewSheetContent: some View {
        Group {
            if let code = generatedCode {
                BrowserPreviewView(html: code)
            } else {
                Text("No code generated yet")
            }
        }
    }

    // Extracted code preview sheet content
    private var codePreviewSheetContent: some View {
        Group {
            if let code = generatedCode {
                VStack(spacing: 0) {
                    AnimatedCodePreview(code: code)
                    Divider()
                    FollowUpChatView(
                        chatHistory: $chatHistory,
                        followUpInput: $followUpInput,
                        onSend: { userMsg in
                            chatHistory.append((role: "user", content: userMsg))
                            followUpInput = ""
                            let conversationDicts = chatHistoryDicts
                            ChatGPTService.shared.generateCode(prompt: userMsg, model: selectedModel, conversation: conversationDicts) { result in
                                switch result {
                                case .success(let reply):
                                    chatHistory.append((role: "assistant", content: reply))
                                case .failure(let error):
                                    chatHistory.append((role: "assistant", content: "Error: \(error.localizedDescription)"))
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    // Ensure Picker selections are always valid
    private func validatePickerSelections() {
        if !availableModels.contains(selectedModel) {
            selectedModel = availableModels.first ?? ""
        }
        if !promptTemplates.contains(selectedPromptTemplate) {
            selectedPromptTemplate = promptTemplates.first ?? ""
        }
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

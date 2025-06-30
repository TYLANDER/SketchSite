import SwiftUI
import PencilKit
import PhotosUI

/// A UIViewRepresentable wrapper for PKCanvasView, enabling PencilKit drawing in SwiftUI.
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let isDrawingEnabled: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        updateDrawingState()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        updateDrawingState()
    }
    
    private func updateDrawingState() {
        if isDrawingEnabled {
            // Enable drawing - set default tool
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
            canvasView.isUserInteractionEnabled = true
            print("🎨 Drawing enabled")
        } else {
            // Disable drawing by setting user interaction to false
            canvasView.isUserInteractionEnabled = false
            print("🚫 Drawing disabled - component selected")
        }
    }
}

/// The main container view for the sketching experience, with a full-screen canvas and overlay toolbars.
struct CanvasContainerView: View {
    // Core managers - centralized state management
    @StateObject private var canvasStateManager = CanvasStateManager()
    @StateObject private var componentManager = ComponentManager()
    @StateObject private var errorManager = ErrorManager()
    
    // UI state
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    
    // Analysis and generation state
    @State private var isAnalyzing = false
    @State private var generatedCode: String = ""
    @State private var isGeneratingCode = false
    @State private var showCodePreview = false
    @State private var showBrowserPreview = false
    @State private var selectedModel = "gpt-4o"
    @State private var showInspector = false
    @State private var showComponentLibrary = false
    
    // Canvas size tracking
    @State private var canvasSize: CGSize = UIScreen.main.bounds.size
    
    private let visionService = VisionAnalysisService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen canvas background with tap-to-deselect
                CanvasView(canvasView: $canvasStateManager.canvasView, isDrawingEnabled: !componentManager.isComponentSelected)
                    .ignoresSafeArea(.all)
                    .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                        canvasStateManager.updateStrokeCount()
                        
                        // Update canvas size from geometry
                        let newSize = geometry.size
                        if newSize != canvasSize {
                            canvasSize = newSize
                            canvasStateManager.updateCanvasSize(newSize)
                            componentManager.updateCanvasSize(newSize)
                            print("📐 Canvas size updated: \(canvasSize)")
                        }
                    }
                
                // Invisible overlay to handle background taps when component is selected
                if componentManager.isComponentSelected {
                    Color.clear
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            componentManager.deselectComponent()
                            print("🔘 Deselected component by tapping background")
                        }
                        .allowsHitTesting(true)
                }
                
                // Component overlays with individual tap, drag, and resize handling
                ForEach(Array(componentManager.components.enumerated()), id: \.element.id) { index, component in
                    ComponentOverlayView(
                        comp: component,
                        idx: index,
                        isSelected: componentManager.selectedComponentID == component.id,
                        onTap: {
                            print("🔘 Component tap received for: \(component.type.description)")
                            componentManager.toggleComponentSelection(withID: component.id)
                        },
                        onDrag: { newPosition in
                            componentManager.updateComponentPosition(at: index, to: newPosition)
                        },
                        onResize: { newRect in
                            componentManager.updateComponentSize(at: index, to: newRect)
                        },
                        onInspect: {
                            showInspector = true
                            print("🔍 Opening inspector for: \(component.type.description)")
                        },
                        canvasSize: canvasSize
                    )
                    .allowsHitTesting(true) // Ensure component overlays can receive touches
                    .background(Color.clear) // Transparent background for touch handling
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
            .onAppear {
                canvasSize = geometry.size
                canvasStateManager.updateCanvasSize(canvasSize)
                componentManager.updateCanvasSize(canvasSize)
                print("📐 Initial canvas size: \(canvasSize)")
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
            .sheet(isPresented: $showInspector) {
                if let selectedID = componentManager.selectedComponentID,
                   let componentIndex = componentManager.components.firstIndex(where: { $0.id == selectedID }) {
                    NavigationView {
                        InspectorView(component: Binding(
                            get: { 
                                componentManager.components[componentIndex]
                            },
                            set: { newComponent in
                                componentManager.updateComponent(at: componentIndex, with: newComponent)
                                print("✏️ Updated component: \(newComponent.type.description)")
                            }
                        ))
                        .navigationTitle("Edit Component")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { 
                                    showInspector = false
                                    componentManager.deselectComponent()
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .alert("Error", isPresented: $errorManager.showErrorAlert) {
                Button("OK") { 
                    errorManager.dismissCurrentError()
                }
            } message: {
                Text(errorManager.currentError?.errorDescription ?? "Unknown error occurred")
            }
            .sheet(isPresented: $showCodePreview) {
                CodePreviewView(code: generatedCode)
            }
            .sheet(isPresented: $showBrowserPreview) {
                NavigationView {
                    BrowserPreviewView(html: generatedCode)
                        .navigationTitle("Live Preview")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showBrowserPreview = false }
                            }
                            ToolbarItem(placement: .primaryAction) {
                                Button("View Code") { 
                                    showBrowserPreview = false
                                    showCodePreview = true
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showComponentLibrary) {
                ComponentLibraryView { template in
                    addLibraryComponent(template)
                }
            }
        }
    }

    // MARK: - Top Header
    private var topBar: some View {
        VStack(spacing: 0) {
            // Status bar spacer
            Color.clear
                .frame(height: 50)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SketchSite")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if componentManager.isComponentSelected {
                        Text("Component selected • Tap to deselect")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Draw mode • Tap component to select")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                

                
                // Show component count when components are detected
                if !componentManager.components.isEmpty {
                    Text("\(componentManager.components.count) components")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                
                Picker("Model", selection: $selectedModel) {
                    Text("gpt-4o").tag("gpt-4o")
                    Text("gpt-3.5-turbo").tag("gpt-3.5-turbo")
                    Text("claude-3-opus").tag("claude-3-opus")
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
                Button(action: { canvasStateManager.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                }
                .disabled(!canvasStateManager.canUndo)
                
                Button(action: clearCanvas) {
                    Image(systemName: "trash")
                        .font(.title2)
                }
                
                Button(action: { canvasStateManager.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title2)
                }
                .disabled(!canvasStateManager.canRedo)
                
                // Component Library button
                Button(action: { showComponentLibrary = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "square.grid.2x2")
                            .font(.title2)
                        Text("Library")
                            .font(.caption)
                    }
                }
                
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
                .disabled(isAnalyzing || !canvasStateManager.hasStrokes)
                .onAppear {
                    print("🔧 Generate button appeared. Initial stroke count: \(canvasStateManager.currentStrokeCount)")
                }
                
                Spacer()
                
                // Code generation and preview buttons
                if !componentManager.components.isEmpty {
                    Button(action: generateCode) {
                        HStack(spacing: 4) {
                            if isGeneratingCode {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "doc.text")
                                    .font(.title2)
                            }
                            Text(isGeneratingCode ? "Generating..." : "Code")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .disabled(isGeneratingCode)
                    
                    if !generatedCode.isEmpty {
                        Button(action: { showBrowserPreview = true }) {
                            VStack(spacing: 2) {
                                Image(systemName: "safari")
                                    .font(.title2)
                                Text("Preview")
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
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
    private func clearCanvas() {
        canvasStateManager.clearCanvas()
        // Clear EVERYTHING when canvas is cleared - complete reset
        componentManager.clearAllComponents()
        generatedCode = ""
        print("🗑️ Canvas completely cleared - all components and code removed")
    }

    private func pick(_ source: UIImagePickerController.SourceType) {
        imagePickerSource = source
        showImagePicker = true
    }
    
    // MARK: - Vision Analysis
    private func generateComponents() {
        print("🔥 Generate button tapped! currentStrokeCount: \(canvasStateManager.currentStrokeCount)")
        guard canvasStateManager.hasStrokes else { 
            print("❌ No strokes detected, returning early")
            return 
        }
        
        print("✅ Starting cumulative analysis...")
        isAnalyzing = true
        componentManager.deselectComponent() // Clear selection when regenerating
        // Note: Keep existing components and code - we'll add new detections to existing ones
        
        // Take snapshot of current canvas
        guard let canvasImage = canvasStateManager.captureSnapshot() else {
            errorManager.handleCanvasError("Failed to capture canvas image")
            isAnalyzing = false
            return
        }
        
        // Get canvas size for coordinate conversion
        let analysisCanvasSize = canvasSize
        print("📐 Using canvas size for analysis: \(analysisCanvasSize)")
        
        // Run Vision analysis
        visionService.detectLayoutAndAnnotations(in: canvasImage, canvasSize: analysisCanvasSize) { newComponents in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                if newComponents.isEmpty {
                    if self.componentManager.components.isEmpty {
                        self.errorManager.handleError(.visionAnalysisFailed("No UI components detected. Try drawing clearer rectangles or shapes."))
                    } else {
                        print("ℹ️ No new components detected, keeping existing \(self.componentManager.components.count) components")
                    }
                } else {
                    // Merge new components with existing ones, avoiding duplicates
                    let mergedComponents = self.componentManager.mergeComponents(existing: self.componentManager.components, new: newComponents)
                    self.componentManager.setComponents(mergedComponents)
                    
                    let totalCount = mergedComponents.count
                    let newCount = newComponents.count
                    print("✅ Analysis complete: \(newCount) new + \(totalCount - newCount) existing = \(totalCount) total components:")
                    for (idx, comp) in mergedComponents.enumerated() {
                        print("  \(idx + 1). \(comp.type.description) at \(comp.rect)")
                    }
                }
            }
        }
    }

    
    // MARK: - Code Generation
    private func generateCode() {
        guard !componentManager.components.isEmpty else { return }
        
        print("🎨 Starting code generation for \(componentManager.components.count) components...")
        isGeneratingCode = true
        
        // Create layout description
        let layoutDescription = LayoutDescriptor.describe(components: componentManager.components, canvasSize: canvasSize)
        
        // Build comprehensive prompt
        let prompt = buildCodeGenerationPrompt(layoutDescription: layoutDescription, canvasSize: canvasSize)
        
        // Generate code using ChatGPT
        ChatGPTService.shared.generateCode(prompt: prompt, model: selectedModel) { result in
            DispatchQueue.main.async {
                self.isGeneratingCode = false
                
                switch result {
                case .success(let code):
                    self.generatedCode = code
                    self.showCodePreview = true
                    print("✅ Code generation successful! Generated \(code.count) characters")
                    
                case .failure(let error):
                    self.errorManager.handleError(.codeGenerationFailed(error.localizedDescription))
                    print("❌ Code generation failed: \(error)")
                }
            }
        }
    }
    
    private func buildCodeGenerationPrompt(layoutDescription: String, canvasSize: CGSize) -> String {
        return """
        You are an expert frontend developer. Generate clean, modern HTML and CSS code based on this UI sketch analysis.

        **Canvas Size:** \(Int(canvasSize.width)) × \(Int(canvasSize.height)) pixels

        **Detected Components:**
        \(layoutDescription)

        **Requirements:**
        - Generate complete, valid HTML5 with embedded CSS
        - Use modern CSS (flexbox/grid for layout)
        - Make it responsive and mobile-friendly
        - Use semantic HTML elements
        - Include hover effects and smooth transitions
        - Use a modern color scheme (avoid default browser styles)
        - Make buttons and interactive elements accessible
        - Include proper meta tags and viewport settings

        **Style Guidelines:**
        - Use a clean, professional design system
        - Consistent spacing and typography
        - Subtle shadows and rounded corners where appropriate
        - Modern color palette (consider blues, grays, whites)
        - Ensure good contrast for accessibility

        Please provide only the complete HTML file with embedded CSS. No explanations needed.
        """
    }
    
    // MARK: - Component Library
    
    private func addLibraryComponent(_ template: ComponentTemplate) {
        // Calculate center position with slight randomization to avoid overlapping
        let centerX = canvasSize.width / 2 + CGFloat.random(in: -50...50)
        let centerY = canvasSize.height / 2 + CGFloat.random(in: -50...50)
        let position = CGPoint(x: centerX, y: centerY)
        
        componentManager.addLibraryComponent(from: template, at: position)
        print("📚 Added library component: \(template.name)")
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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

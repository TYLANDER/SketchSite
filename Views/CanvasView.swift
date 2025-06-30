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
    @State private var currentStrokeCount = 0
    
    // Code generation state
    @State private var generatedCode: String = ""
    @State private var isGeneratingCode = false
    @State private var showCodePreview = false
    @State private var showBrowserPreview = false
    @State private var selectedModel = "gpt-4o"
    
    // Component selection and inspection state
    @State private var selectedComponentID: UUID? = nil
    @State private var showInspector = false
    
    // Canvas size tracking
    @State private var canvasSize: CGSize = UIScreen.main.bounds.size
    
    private let visionService = VisionAnalysisService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen canvas background with tap-to-deselect
                CanvasView(canvasView: $canvasView, isDrawingEnabled: selectedComponentID == nil)
                    .ignoresSafeArea(.all)
                    .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                        let newCount = canvasView.drawing.strokes.count
                        if newCount != currentStrokeCount {
                            print("📝 Stroke count changed! Old: \(currentStrokeCount), New: \(newCount)")
                            currentStrokeCount = newCount
                        }
                        
                        // Update canvas size from geometry
                        let newSize = geometry.size
                        if newSize != canvasSize {
                            canvasSize = newSize
                            print("📐 Canvas size updated: \(canvasSize)")
                        }
                    }
                
                // Invisible overlay to handle background taps when component is selected
                if selectedComponentID != nil {
                    Color.clear
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            selectedComponentID = nil
                            print("🔘 Deselected component by tapping background")
                        }
                        .allowsHitTesting(true)
                }
                
                // Component overlays with individual tap, drag, and resize handling
                ForEach(Array(detectedComponents.enumerated()), id: \.element.id) { index, component in
                    ComponentOverlayView(
                        comp: component,
                        idx: index,
                        isSelected: selectedComponentID == component.id,
                        onTap: {
                            print("🔘 Component tap received for: \(component.type.description)")
                            if selectedComponentID == component.id {
                                // Tap selected component - deselect it
                                selectedComponentID = nil
                                print("🔘 Deselected component: \(component.type.description)")
                            } else {
                                // Tap unselected component - select it
                                selectedComponentID = component.id
                                print("🔵 Selected component: \(component.type.description)")
                            }
                        },
                        onDrag: { newPosition in
                            updateComponentPosition(at: index, to: newPosition)
                        },
                        onResize: { newRect in
                            updateComponentSize(at: index, to: newRect)
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
                if let selectedID = selectedComponentID,
                   let componentIndex = detectedComponents.firstIndex(where: { $0.id == selectedID }) {
                    NavigationView {
                        InspectorView(component: Binding(
                            get: { 
                                detectedComponents[componentIndex]
                            },
                            set: { newComponent in
                                detectedComponents[componentIndex] = newComponent
                                print("✏️ Updated component: \(newComponent.type.description)")
                            }
                        ))
                        .navigationTitle("Edit Component")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { 
                                    showInspector = false
                                    selectedComponentID = nil
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .alert("Analysis Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(analysisError ?? "Unknown error occurred")
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
                    
                    if selectedComponentID != nil {
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
                if !detectedComponents.isEmpty {
                    Text("\(detectedComponents.count) components")
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
                .disabled(isAnalyzing || currentStrokeCount == 0)
                .onAppear {
                    print("🔧 Generate button appeared. Initial stroke count: \(canvasView.drawing.strokes.count)")
                }
                
                Spacer()
                
                // Code generation and preview buttons
                if !detectedComponents.isEmpty {
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
        currentStrokeCount = 0
        // Clear EVERYTHING when canvas is cleared - complete reset
        detectedComponents.removeAll()
        selectedComponentID = nil
        generatedCode = ""
        print("🗑️ Canvas completely cleared - all components and code removed")
    }

    private func pick(_ source: UIImagePickerController.SourceType) {
        imagePickerSource = source
        showImagePicker = true
    }
    
    // MARK: - Vision Analysis
    private func generateComponents() {
        let strokeCount = canvasView.drawing.strokes.count
        print("🔥 Generate button tapped! currentStrokeCount: \(currentStrokeCount), actual strokeCount: \(strokeCount)")
        guard strokeCount > 0 else { 
            print("❌ No strokes detected, returning early")
            return 
        }
        
        print("✅ Starting cumulative analysis...")
        isAnalyzing = true
        analysisError = nil
        selectedComponentID = nil // Clear selection when regenerating
        // Note: Keep existing components and code - we'll add new detections to existing ones
        
        // Take snapshot of current canvas
        guard let canvasImage = canvasView.snapshotImage() else {
            analysisError = "Failed to capture canvas image"
            showErrorAlert = true
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
                    if self.detectedComponents.isEmpty {
                        self.analysisError = "No UI components detected. Try drawing clearer rectangles or shapes."
                        self.showErrorAlert = true
                    } else {
                        print("ℹ️ No new components detected, keeping existing \(self.detectedComponents.count) components")
                    }
                } else {
                    // Merge new components with existing ones, avoiding duplicates
                    let mergedComponents = self.mergeComponents(existing: self.detectedComponents, new: newComponents)
                    self.detectedComponents = mergedComponents
                    
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
    
    // MARK: - Component Position Updates
    
    /// Updates the position of a component after it has been dragged.
    private func updateComponentPosition(at index: Int, to newPosition: CGPoint) {
        guard index < detectedComponents.count else {
            print("❌ Invalid component index: \(index)")
            return
        }
        
        let component = detectedComponents[index]
        let oldRect = component.rect
        
        // Calculate new rect maintaining the same size but updating position
        // newPosition represents the center point of the component
        let newRect = CGRect(
            x: newPosition.x - oldRect.width / 2,
            y: newPosition.y - oldRect.height / 2,
            width: oldRect.width,
            height: oldRect.height
        )
        
        // Clamp the new rect to canvas bounds
        let clampedRect = clampRectToCanvas(newRect, canvasSize: canvasSize)
        
        // Update the component
        detectedComponents[index].rect = clampedRect
        
        print("📍 Updated component \(index + 1) position:")
        print("   Old: \(oldRect)")
        print("   New: \(clampedRect)")
        
        // If this component was selected, keep it selected
        if selectedComponentID == component.id {
            print("🔄 Maintaining selection for moved component")
        }
    }
    
    /// Updates the size of a component after it has been resized.
    private func updateComponentSize(at index: Int, to newRect: CGRect) {
        guard index < detectedComponents.count else {
            print("❌ Invalid component index: \(index)")
            return
        }
        
        let component = detectedComponents[index]
        let oldRect = component.rect
        
        // Clamp the new rect to canvas bounds
        let clampedRect = clampRectToCanvas(newRect, canvasSize: canvasSize)
        
        // Update the component
        detectedComponents[index].rect = clampedRect
        
        print("📏 Updated component \(index + 1) size:")
        print("   Old: \(oldRect)")
        print("   New: \(clampedRect)")
        
        // If this component was selected, keep it selected
        if selectedComponentID == component.id {
            print("🔄 Maintaining selection for resized component")
        }
    }
    
    /// Clamps a rectangle to stay within canvas bounds.
    private func clampRectToCanvas(_ rect: CGRect, canvasSize: CGSize) -> CGRect {
        let canvasBounds = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
        
        var clampedRect = rect
        
        // Ensure the rectangle doesn't go outside the left or right edges
        if clampedRect.minX < canvasBounds.minX {
            clampedRect.origin.x = canvasBounds.minX
        } else if clampedRect.maxX > canvasBounds.maxX {
            clampedRect.origin.x = canvasBounds.maxX - clampedRect.width
        }
        
        // Ensure the rectangle doesn't go outside the top or bottom edges
        if clampedRect.minY < canvasBounds.minY {
            clampedRect.origin.y = canvasBounds.minY
        } else if clampedRect.maxY > canvasBounds.maxY {
            clampedRect.origin.y = canvasBounds.maxY - clampedRect.height
        }
        
        return clampedRect
    }
    
    // MARK: - Component Merging
    
    /// Merges new components with existing ones, avoiding duplicates based on position and size similarity.
    private func mergeComponents(existing: [DetectedComponent], new: [DetectedComponent]) -> [DetectedComponent] {
        var merged = existing
        let positionTolerance: CGFloat = 30.0 // pixels
        let sizeTolerance: CGFloat = 20.0 // pixels
        
        for newComponent in new {
            var isDuplicate = false
            
            // Check if this new component is similar to any existing component
            for existingComponent in existing {
                let positionDistance = hypot(
                    newComponent.rect.midX - existingComponent.rect.midX,
                    newComponent.rect.midY - existingComponent.rect.midY
                )
                let sizeDistance = hypot(
                    newComponent.rect.width - existingComponent.rect.width,
                    newComponent.rect.height - existingComponent.rect.height
                )
                
                if positionDistance < positionTolerance && sizeDistance < sizeTolerance {
                    print("🔄 Skipping duplicate component: \(newComponent.type.description) at \(newComponent.rect)")
                    isDuplicate = true
                    break
                }
            }
            
            if !isDuplicate {
                merged.append(newComponent)
                print("➕ Added new component: \(newComponent.type.description) at \(newComponent.rect)")
            }
        }
        
        return merged
    }
    
    // MARK: - Code Generation
    private func generateCode() {
        guard !detectedComponents.isEmpty else { return }
        
        print("🎨 Starting code generation for \(detectedComponents.count) components...")
        isGeneratingCode = true
        
        // Create layout description
        let canvasSize = canvasView.bounds.size
        let layoutDescription = LayoutDescriptor.describe(components: detectedComponents, canvasSize: canvasSize)
        
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
                    self.analysisError = "Code generation failed: \(error.localizedDescription)"
                    self.showErrorAlert = true
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

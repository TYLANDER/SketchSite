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
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
            canvasView.isUserInteractionEnabled = true
        } else {
            canvasView.isUserInteractionEnabled = false
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
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        if isAnalyzing {
            return "Analyzing drawing..."
        } else if isGeneratingCode {
            return "Generating code..."
        } else if canvasStateManager.hasStrokes && componentManager.components.isEmpty {
            return "Draw shapes, then tap Generate"
        } else if !canvasStateManager.hasStrokes {
            return "Start drawing or add components"
        } else {
            return "Ready to generate code"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grey canvas background
                Color(.systemGray6)
                    .ignoresSafeArea(.all)
                
                // Full-screen canvas - true edge-to-edge
                CanvasView(canvasView: $canvasStateManager.canvasView, isDrawingEnabled: !componentManager.isComponentSelected)
                    .ignoresSafeArea(.all)
                    .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                        canvasStateManager.updateStrokeCount()
                        
                        // Update canvas size from screen bounds for true full-screen
                        let newSize = UIScreen.main.bounds.size
                        if newSize != canvasSize {
                            canvasSize = newSize
                            canvasStateManager.updateCanvasSize(newSize)
                            componentManager.updateCanvasSize(newSize)
                        }
                    }
                    .background(Color(.systemGray6))
                
                // Component overlays with individual tap, drag, and resize handling
                ForEach(Array(componentManager.components.enumerated()), id: \.element.id) { index, component in
                    ComponentOverlayView(
                        comp: Binding(
                            get: { 
                                // Use ID-based lookup to avoid stale index references
                                let foundComponent = componentManager.components.first { $0.id == component.id } ?? component
                                print("🔍 ComponentOverlayView binding get: component \(index + 1) - \(foundComponent.type.description) at \(foundComponent.rect)")
                                return foundComponent
                            },
                            set: { newComponent in 
                                // Update by ID to ensure we're updating the correct component
                                print("🔍 ComponentOverlayView binding set: updating component \(component.id)")
                                componentManager.updateComponent(withID: component.id, newComponent: newComponent)
                            }
                        ),
                        idx: index,
                        isSelected: componentManager.selectedComponentID == component.id,
                        onTap: {
                            // Always just select the component on tap
                            componentManager.selectComponent(withID: component.id)
                        },
                        onDrag: { newPosition in
                            componentManager.updateComponentPosition(withID: component.id, to: newPosition)
                        },
                        onResize: { newRect in
                            componentManager.updateComponentSize(withID: component.id, to: newRect)
                        },
                        onInspect: {
                            showInspector = true
                        },
                        canvasSize: canvasSize
                    )
                    .allowsHitTesting(true)
                    .zIndex(10) // Component overlays
                    .onAppear {
                        print("🎯 ComponentOverlayView appeared: component \(index + 1) - \(component.type.description) at \(component.rect)")
                    }
                    .onDisappear {
                        print("❌ ComponentOverlayView disappeared: component \(index + 1) - \(component.type.description)")
                    }
                }
                .onAppear {
                    print("📋 ForEach appeared with \(componentManager.components.count) components")
                    for (i, comp) in componentManager.components.enumerated() {
                        print("  Component \(i + 1): \(comp.type.description) at \(comp.rect)")
                    }
                }
                
                // Invisible overlay to handle background taps for deselecting components
                // This needs to be AFTER components in the view hierarchy but with higher zIndex
                if componentManager.isComponentSelected {
                    Color.clear
                        .ignoresSafeArea(.all)
                        .contentShape(Rectangle()) // Ensure it captures taps everywhere
                        .onTapGesture {
                            componentManager.deselectComponent()
                        }
                        .allowsHitTesting(true)
                        .zIndex(15) // Higher than components to intercept background taps
                }
                
                // Top header overlay - positioned below status bar
                VStack {
                    topBar(geometry: geometry)
                    Spacer()
                }
                .zIndex(20)
                
                // Bottom toolbar overlay - positioned above home indicator
                VStack {
                    Spacer()
                    bottomToolbar(geometry: geometry)
                    // Add spacer to raise toolbar above home indicator
                    Color.clear
                        .frame(height: max(geometry.safeAreaInsets.bottom + 48, 48))
                }
                .zIndex(20)
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            canvasSize = UIScreen.main.bounds.size
            canvasStateManager.updateCanvasSize(canvasSize)
            componentManager.updateCanvasSize(canvasSize)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: imagePickerSource) { image in
                if let img = image {
                    selectedImage = img
                }
                showImagePicker = false
            }
        }
        .sheet(isPresented: $showInspector) {
            if let selectedID = componentManager.selectedComponentID {
                NavigationView {
                    InspectorView(
                        component: Binding(
                            get: { 
                                // Always find the current component by ID to avoid stale references
                                componentManager.components.first { $0.id == selectedID } ?? DetectedComponent(
                                    rect: CGRect(x: 0, y: 0, width: 100, height: 50),
                                    type: .ui(.label),
                                    label: nil
                                )
                            },
                            set: { newComponent in
                                // Update by ID to ensure we're updating the correct component
                                componentManager.updateComponent(withID: selectedID, newComponent: newComponent)
                            }
                        ),
                        canvasSize: canvasSize
                    )
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
            } else {
                // Fallback view if no component is selected
                NavigationView {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("No Component Selected")
                            .font(.headline)
                        Text("Please select a component to inspect.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .navigationTitle("Inspector")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { 
                                showInspector = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
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

    // MARK: - Top Header
    private func topBar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Dynamic status bar spacer + extra padding to move header down
            Color.clear
                .frame(height: geometry.safeAreaInsets.top + 56)
            
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("SketchSite")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                    
                    Spacer(minLength: 8)
                    
                    // Model picker with flexible width
                    Picker("Model", selection: $selectedModel) {
                        Text("gpt-4o").tag("gpt-4o")
                        Text("gpt-3.5").tag("gpt-3.5-turbo")
                        Text("claude").tag("claude-3-opus")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(minWidth: 60, maxWidth: 100)
                    .layoutPriority(-1)
                }
                
                // Status subcopy
                HStack {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if componentManager.components.count > 0 {
                        Text("\(componentManager.components.count) component\(componentManager.components.count != 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                Color(.systemGray5)
                    .opacity(0.95)
            )
            .cornerRadius(12)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: - Bottom Toolbar
    private func bottomToolbar(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 8)
            
            // Undo button
            Button(action: { canvasStateManager.undo() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .disabled(!canvasStateManager.canUndo)
            
            Spacer()
            
            // Clear button
            Button(action: clearCanvas) {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Redo button
            Button(action: { canvasStateManager.redo() }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .disabled(!canvasStateManager.canRedo)
            
            Spacer()
            
            // Library button
            Button(action: { showComponentLibrary = true }) {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Generate button
            Button(action: generateComponents) {
                Image(systemName: isAnalyzing ? "wand.and.rays.inverse" : "wand.and.rays")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .disabled(isAnalyzing || !canvasStateManager.hasStrokes)
            
            Spacer()
            
            // Camera button
            Button(action: { pick(.camera) }) {
                Image(systemName: "camera")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Photo library button
            Button(action: { pick(.photoLibrary) }) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer(minLength: 8)
        }
        .padding(.vertical, 12)
        .background(
            Color(.systemGray5)
                .opacity(0.95)
        )
        .cornerRadius(12)
        .padding(.horizontal, 8)
    }

    // MARK: - Actions
    private func clearCanvas() {
        canvasStateManager.clearCanvas()
        componentManager.clearAllComponents()
        generatedCode = ""
        
        // Provide haptic feedback for clearing
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }

    private func pick(_ source: UIImagePickerController.SourceType) {
        imagePickerSource = source
        showImagePicker = true
    }
    
    // MARK: - Vision Analysis
    private func generateComponents() {
        guard canvasStateManager.hasStrokes else { 
            print("🚫 Generate components: No strokes on canvas")
            return 
        }
        
        print("🎯 Generate components: Starting analysis...")
        print("📊 Current components before generation: \(componentManager.components.count)")
        
        isAnalyzing = true
        componentManager.deselectComponent()
        
        guard let canvasImage = canvasStateManager.captureSnapshot() else {
            print("❌ Generate components: Failed to capture canvas image")
            errorManager.handleCanvasError("Failed to capture canvas image")
            isAnalyzing = false
            return
        }
        
        print("📸 Generate components: Canvas image captured successfully")
        
        visionService.detectLayoutAndAnnotations(in: canvasImage, canvasSize: canvasSize) { newComponents in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                print("🔍 Vision analysis completed with \(newComponents.count) new components:")
                for (i, comp) in newComponents.enumerated() {
                    print("  New component \(i + 1): \(comp.type.description) at \(comp.rect)")
                }
                
                if newComponents.isEmpty {
                    print("⚠️ No new components detected")
                    if self.componentManager.components.isEmpty {
                        self.errorManager.handleError(.visionAnalysisFailed("No UI components detected. Try drawing clearer rectangles or shapes."))
                    }
                } else {
                    print("🔄 Merging components...")
                    let mergedComponents = self.componentManager.mergeComponents(existing: self.componentManager.components, new: newComponents)
                    print("📦 Setting \(mergedComponents.count) merged components")
                    self.componentManager.setComponents(mergedComponents)
                    
                    print("✅ Components set successfully. Current count: \(self.componentManager.components.count)")
                }
            }
        }
    }

    
    // MARK: - Code Generation
    private func generateCode() {
        guard !componentManager.components.isEmpty else { return }
        
        isGeneratingCode = true
        
        let layoutDescription = LayoutDescriptor.describe(components: componentManager.components, canvasSize: canvasSize)
        let prompt = buildCodeGenerationPrompt(layoutDescription: layoutDescription, canvasSize: canvasSize)
        
        ChatGPTService.shared.generateCode(prompt: prompt, model: selectedModel) { result in
            DispatchQueue.main.async {
                self.isGeneratingCode = false
                
                switch result {
                case .success(let code):
                    self.generatedCode = code
                    self.showCodePreview = true
                    
                case .failure(let error):
                    self.errorManager.handleError(.codeGenerationFailed(error.localizedDescription))
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
        let centerX = canvasSize.width / 2 + CGFloat.random(in: -50...50)
        let centerY = canvasSize.height / 2 + CGFloat.random(in: -50...50)
        let position = CGPoint(x: centerX, y: centerY)
        
        componentManager.addLibraryComponent(from: template, at: position)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#if DEBUG
struct CanvasContainerView_Previews: PreviewProvider {
    static var previews: some View {
        CanvasContainerView()
    }
}
#endif

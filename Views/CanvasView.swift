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
    @StateObject private var sketchManager = SketchManager.shared
    
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
    @State private var showFollowUpChat = false
    @State private var shouldShowPreviewAfterGeneration = false
    @State private var selectedModel = "gpt-4o"
    @State private var showInspector = false
    @State private var showComponentLibrary = false
    
    // Menu and project management
    @State private var showMainMenu = false
    @State private var showSketchManager = false
    
    // Conversation manager for follow-up chat
    @StateObject private var conversationManager = ConversationManager()
    
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
                // Full-screen canvas background
                CanvasView(canvasView: $canvasStateManager.canvasView, isDrawingEnabled: !componentManager.isComponentSelected)
                    .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                        canvasStateManager.updateStrokeCount()
                        let newSize = geometry.size
                        if newSize != canvasSize {
                            canvasSize = newSize
                            canvasStateManager.updateCanvasSize(newSize)
                            componentManager.updateCanvasSize(newSize)
                        }
                    }
                // Component overlays
                ForEach(Array(componentManager.components.enumerated()), id: \.element.id) { index, component in
                    ComponentOverlayView(
                        comp: Binding(
                            get: {
                                let foundComponent = componentManager.components.first { $0.id == component.id } ?? component
                                return foundComponent
                            },
                            set: { newComponent in
                                componentManager.updateComponent(withID: component.id, newComponent: newComponent)
                            }
                        ),
                        idx: index,
                        isSelected: componentManager.selectedComponentID == component.id,
                        onTap: {
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
                    .zIndex(10)
                }
                if componentManager.isComponentSelected {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            componentManager.deselectComponent()
                        }
                        .allowsHitTesting(true)
                        .zIndex(15)
                }
                // Top header overlay
                VStack(spacing: 0) {
                    // Status bar area
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.top)
                    
                    // Reduced spacer - bring header down by 64px
                    Color.clear
                        .frame(height: 80) // Was 16, now 80 (64px more)
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Text("SketchSite")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .allowsTightening(true)
                                
                                Button(action: { showMainMenu = true }) {
                                    Image(systemName: "chevron.down")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Spacer(minLength: 8)
                            
                            Picker("Model", selection: $selectedModel) {
                                Text("gpt-4o").tag("gpt-4o")
                                Text("gpt-3.5").tag("gpt-3.5-turbo")
                                Text("claude").tag("claude-3-opus")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 60, maxWidth: 100)
                            .layoutPriority(-1)
                        }
                        
                        // Status text
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray5).opacity(0.95))
                    
                    // Push everything else down
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .zIndex(20)
                
                // Bottom toolbar overlay
                VStack(spacing: 0) {
                    // Push everything up
                    Spacer()
                    
                    HStack(spacing: 0) {
                        Spacer(minLength: 8)
                        Button(action: { canvasStateManager.undo() }) {
                            Image(systemName: "arrow.uturn.backward").font(.title)
                        }
                        .disabled(!canvasStateManager.canUndo)
                        Spacer()
                        Button(action: clearCanvas) {
                            Image(systemName: "trash").font(.title)
                        }
                        Spacer()
                        Button(action: { canvasStateManager.redo() }) {
                            Image(systemName: "arrow.uturn.forward").font(.title)
                        }
                        .disabled(!canvasStateManager.canRedo)
                        Spacer()
                        Button(action: { showComponentLibrary = true }) {
                            Image(systemName: "square.grid.2x2").font(.title)
                        }
                        Spacer()
                        Button(action: generateComponents) {
                            Image(systemName: isAnalyzing ? "wand.and.rays.inverse" : "wand.and.rays")
                                .font(.title)
                        }
                        .disabled(isAnalyzing || !canvasStateManager.hasStrokes)
                        Spacer()
                        Button(action: openPreview) {
                            Image(systemName: "safari").font(.title)
                        }
                        .disabled(componentManager.components.isEmpty)
                        Spacer()
                        Button(action: { pick(.camera) }) {
                            Image(systemName: "camera").font(.title)
                        }
                        Spacer()
                        Button(action: { pick(.photoLibrary) }) {
                            Image(systemName: "photo").font(.title)
                        }
                        Spacer(minLength: 8)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray5).opacity(0.95))
                    
                    // Reduced spacer - bring toolbar up by 64px
                    Color.clear
                        .frame(height: 80) // Was 16, now 80 (64px more)
                    
                    // Home indicator area
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.bottom)
                }
                .ignoresSafeArea(edges: .bottom)
                .zIndex(20)
            }
        }
        .ignoresSafeArea(edges: .all)
        .onAppear {
            canvasSize = UIScreen.main.bounds.size
            canvasStateManager.updateCanvasSize(canvasSize)
            componentManager.updateCanvasSize(canvasSize)
            loadCurrentProject()
        }
        .onDisappear {
            saveCurrentProject()
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
            CodePreviewView(code: generatedCode) {
                // Dismiss code preview and show follow-up chat
                showCodePreview = false
                openFollowUpChat()
            }
        }
        .sheet(isPresented: $showFollowUpChat) {
            FollowUpChatView(conversationManager: conversationManager)
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
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button("Refine") { 
                                showBrowserPreview = false
                                openFollowUpChat()
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showComponentLibrary) {
            ComponentLibraryView { template in
                componentManager.addLibraryComponent(from: template)
                showComponentLibrary = false
            }
        }
        .sheet(isPresented: $showMainMenu) {
            MainMenuView(
                onOpenFiles: { 
                    showMainMenu = false
                    showSketchManager = true
                },
                onOpenSettings: {
                    // TODO: Implement settings when needed
                    print("Settings tapped - Coming soon!")
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSketchManager) {
            SketchManagerView(
                onProjectSelected: { project in
                    loadProject(project)
                },
                onNewProject: { name in
                    createNewProject(name: name)
                }
            )
        }
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
    
    private func openPreview() {
        if generatedCode.isEmpty {
            // Generate code first, then show preview
            shouldShowPreviewAfterGeneration = true
            generateCode()
        } else {
            // Code already exists, show preview immediately
            showBrowserPreview = true
        }
    }
    
    private func openFollowUpChat() {
        // Configure conversation manager with current context
        conversationManager.configure(
            model: selectedModel,
            components: componentManager.components,
            canvasSize: canvasSize,
            initialCode: generatedCode
        )
        showFollowUpChat = true
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
        guard !componentManager.components.isEmpty else {
            print("🚫 Generate code: No components to generate code for")
            errorManager.handleError(.codeGenerationFailed("No components detected. Please draw some UI elements first."))
            return
        }
        
        print("🎯 Generate code: Starting code generation...")
        isGeneratingCode = true
        
        let layoutDescription = LayoutDescriptor.describe(components: componentManager.components, canvasSize: canvasSize)
        let propertyInstructions = LayoutDescriptor.generatePropertyInstructions(for: componentManager.components)
        
        let prompt = """
        Generate clean, modern HTML and CSS code for this UI layout:
        
        **Canvas Size:** \(Int(canvasSize.width)) × \(Int(canvasSize.height)) pixels
        
        **Components:**
        \(layoutDescription)
        
        **Requirements:**
        - Use semantic HTML5 elements
        - Create responsive CSS with flexbox/grid
        - Use modern CSS with variables for colors
        - Ensure good accessibility with proper ARIA labels
        - Make it mobile-friendly
        - Use a clean, modern design aesthetic
        - Include hover states and smooth transitions
        - Optimize for performance and maintainability\(propertyInstructions)
        
        **Output Format:**
        Provide a complete HTML file with embedded CSS. Include proper DOCTYPE, meta tags, and viewport settings.
        """
        
        ChatGPTService.shared.generateCode(prompt: prompt, model: selectedModel) { result in
            DispatchQueue.main.async {
                self.isGeneratingCode = false
                
                switch result {
                case .success(let code):
                    print("✅ Code generation successful")
                    self.generatedCode = code
                    
                    if self.shouldShowPreviewAfterGeneration {
                        self.shouldShowPreviewAfterGeneration = false
                        self.showBrowserPreview = true
                    } else {
                        self.showCodePreview = true
                    }
                    
                case .failure(let error):
                    print("❌ Code generation failed: \(error.localizedDescription)")
                    self.errorManager.handleError(.codeGenerationFailed(error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: - Project Management
    
    private func loadCurrentProject() {
        guard let currentProject = sketchManager.currentProject else {
            print("📁 No current project to load")
            return
        }
        
        // Load components
        componentManager.setComponents(currentProject.components)
        
        // Load drawing if available
        if let drawing = currentProject.drawing {
            canvasStateManager.loadDrawing(drawing)
        }
        
        // Update canvas size if different
        if currentProject.canvasSize != canvasSize {
            canvasSize = currentProject.canvasSize
            canvasStateManager.updateCanvasSize(canvasSize)
            componentManager.updateCanvasSize(canvasSize)
        }
        
        print("📂 Loaded project: \(currentProject.name)")
    }
    
    private func saveCurrentProject() {
        // Auto-save current state
        sketchManager.saveCurrentState(
            components: componentManager.components,
            drawing: canvasStateManager.currentDrawing,
            canvasSize: canvasSize
        )
        
        // Generate thumbnail from canvas
        if let canvasImage = canvasStateManager.captureSnapshot(),
           let currentProject = sketchManager.currentProject {
            sketchManager.generateThumbnail(for: currentProject, from: canvasImage)
        }
    }
    
    private func loadProject(_ project: SketchProject) {
        // Save current state before switching
        saveCurrentProject()
        
        // Load the selected project
        sketchManager.loadProject(project)
        loadCurrentProject()
        
        print("🔄 Switched to project: \(project.name)")
    }
    
    private func createNewProject(name: String) {
        // Save current state before creating new
        saveCurrentProject()
        
        // Create new project
        let newProject = sketchManager.createNewProject(name: name, canvasSize: canvasSize)
        
        // Clear canvas for new project
        canvasStateManager.resetToInitialState()
        componentManager.clearAllComponents()
        generatedCode = ""
        
        print("📁 Created new project: \(name)")
    }
}

#if DEBUG
struct CanvasContainerView_Previews: PreviewProvider {
    static var previews: some View {
        CanvasContainerView()
    }
}
#endif

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
    @State private var showLibraryManager = false
    @State private var showLibraryCreator = false
    
    // Menu and project management
    @State private var showMainMenu = false
    @State private var showSketchManager = false
    
    // Conversation manager for follow-up chat
    @StateObject private var conversationManager = ConversationManager()
    @StateObject private var libraryManager = ComponentLibraryManager.shared
    
    // Canvas size tracking
    @State private var canvasSize: CGSize = UIScreen.main.bounds.size
    
    private let visionService = VisionAnalysisService()
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        if isAnalyzing {
            return "Analyzing drawing..."
        } else if isGeneratingCode {
            return "Generating \(libraryManager.currentPack.name) code..."
        } else if canvasStateManager.hasStrokes && componentManager.components.isEmpty {
            return "Draw shapes, then tap Generate"
        } else if !canvasStateManager.hasStrokes && componentManager.components.isEmpty {
            return "Start drawing or add components"
        } else if !componentManager.components.isEmpty {
            return "\(componentManager.components.count) components • \(libraryManager.currentPack.name)"
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
                    
                    Color.clear
                        .frame(height: 40)
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            HStack(spacing: 4) {
                                Text("SketchSite")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .allowsTightening(true)
                                
                                Button(action: { showMainMenu = true }) {
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Spacer()
                            
                            Picker("Model", selection: $selectedModel) {
                                Text("GPT-4o").tag("gpt-4o")
                                Text("GPT-3.5").tag("gpt-3.5-turbo")
                                Text("Claude").tag("claude-3-opus")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 70, maxWidth: 120)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.trailing, 4)
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
                        Spacer(minLength: 16)
                        Button(action: { canvasStateManager.undo() }) {
                            Image(systemName: "arrow.uturn.backward").font(.title)
                        }
                        .disabled(!canvasStateManager.canUndo)
                        Spacer()
                        Button(action: clearCanvas) {
                            Image(systemName: "trash").font(.title)
                        }
                        Spacer()
                        Button(action: generateComponentsAndCode) {
                            Image(systemName: isAnalyzing ? "wand.and.rays.inverse" : "wand.and.rays")
                                .font(.title)
                        }
                        .disabled(isAnalyzing || isGeneratingCode)
                        Spacer()
                        Button(action: openPreview) {
                            Image(systemName: "safari").font(.title)
                        }
                        .disabled(componentManager.components.isEmpty)
                        Spacer()
                        Button(action: { showComponentLibrary = true }) {
                            Image(systemName: "plus.square").font(.title)
                        }
                        Spacer()
                        Button(action: { pick(.camera) }) {
                            Image(systemName: "photo").font(.title)
                        }
                        Spacer(minLength: 16)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray5).opacity(0.95))
                    
                    Color.clear
                        .frame(height: 24)
                    
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
                    .toolbar(content: {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { 
                                showInspector = false
                                
                                // Force refresh after a short delay to ensure component updates are processed
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    componentManager.deselectComponent()
                                    
                                    // Force refresh the component list
                                    let currentComponents = componentManager.components
                                    print("🔄 Inspector closed, refreshing \(currentComponents.count) components")
                                    for (i, comp) in currentComponents.enumerated() {
                                        print("  Updated component \(i + 1): \(comp.type.description)")
                                    }
                                    
                                    // Clear and regenerate code to ensure fresh state
                                    generatedCode = ""
                                }
                            }
                        }
                    })
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
                    .toolbar(content: {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { 
                                showInspector = false
                            }
                        }
                    })
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
                    .toolbar(content: {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showBrowserPreview = false }
                        }
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button("Refine") { 
                                showBrowserPreview = false
                                openFollowUpChat()
                            }
                        }
                    })
            }
        }
        .sheet(isPresented: $showComponentLibrary) {
            ComponentLibraryView { template in
                componentManager.addLibraryComponent(from: template)
                showComponentLibrary = false
                
                // Force refresh after adding library component
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let currentComponents = componentManager.components
                    print("📚 Library component added, now have \(currentComponents.count) components")
                    for (i, comp) in currentComponents.enumerated() {
                        print("  Component \(i + 1): \(comp.type.description) - \(comp.label ?? "no label")")
                    }
                    
                    // Clear generated code to force regeneration
                    generatedCode = ""
                }
            }
        }
        .sidebarOverlay(isPresented: $showMainMenu) {
            MainMenuView(
                onOpenFiles: { 
                    showMainMenu = false
                    showSketchManager = true
                },
                onOpenSettings: {
                    // TODO: Implement settings when needed
                    print("Settings tapped - Coming soon!")
                },
                onSwitchLibrary: {
                    showMainMenu = false
                    showLibraryManager = true
                },
                onAddLibrary: {
                    showMainMenu = false
                    showLibraryCreator = true
                },
                onDismiss: {
                    showMainMenu = false
                }
            )
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
        .sheet(isPresented: $showLibraryManager) {
            LibraryManagerView()
        }
        .sheet(isPresented: $showLibraryCreator) {
            LibraryCreatorView()
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
        // Always regenerate code to ensure latest component changes
        shouldShowPreviewAfterGeneration = true
        generateCode()
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
    
    private func generateComponentsAndCode() {
        if canvasStateManager.hasStrokes {
            // If there are strokes, analyze first then generate code
            generateComponents { success in
                if success || !componentManager.components.isEmpty {
                    generateCode()
                }
            }
        } else if !componentManager.components.isEmpty {
            // If no strokes but we have components, just generate code
            generateCode()
        }
    }
    
    private func generateComponents(completion: @escaping (Bool) -> Void = { _ in }) {
        guard canvasStateManager.hasStrokes else { 
            print("🚫 Generate components: No strokes on canvas")
            completion(false)
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
            completion(false)
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
                        completion(false)
                    } else {
                        completion(true) // We have existing components
                    }
                } else {
                    print("🔄 Merging components...")
                    let mergedComponents = self.componentManager.mergeComponents(existing: self.componentManager.components, new: newComponents)
                    print("📦 Setting \(mergedComponents.count) merged components")
                    self.componentManager.setComponents(mergedComponents)
                    
                    print("✅ Components set successfully. Current count: \(self.componentManager.components.count)")
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Code Generation
    private func generateCode() {
        guard !componentManager.components.isEmpty else {
            print("🚫 Generate code: No components to generate code for")
            errorManager.handleError(.codeGenerationFailed("No components detected. Please draw some UI elements or add from library first."))
            return
        }
        
        // Validate component data before sending to AI
        let validComponents = componentManager.components.filter { comp in
            return comp.rect.width > 0 && comp.rect.height > 0
        }
        
        guard !validComponents.isEmpty else {
            print("🚫 Generate code: All components have invalid dimensions")
            errorManager.handleError(.codeGenerationFailed("Component data is invalid. Please recreate your components."))
            return
        }
        
        print("🎯 Generate code: Starting code generation...")
        print("📊 Valid components for code generation (\(validComponents.count) total):")
        for (i, comp) in validComponents.enumerated() {
            print("  Component \(i + 1): TYPE=\(comp.type.description) - LABEL='\(comp.label ?? "none")' - TEXT='\(comp.textContent ?? "none")' - RECT=\(comp.rect)")
        }
        
        // Verify we have actual components, not just placeholders
        let componentTypes = validComponents.map { $0.type.description }
        print("🔍 Component types being sent to AI: \(componentTypes)")
        
        // Count component types
        let typeCounts = Dictionary(grouping: componentTypes, by: { $0 }).mapValues { $0.count }
        print("📈 Component type breakdown: \(typeCounts)")
        
        // Check for suspicious patterns
        if typeCounts.count == 1 && typeCounts.keys.first == "form control" {
            print("⚠️ WARNING: Only form controls detected - this might be incorrect component detection")
        }
        
        isGeneratingCode = true
        
        let layoutDescription = LayoutDescriptor.describe(components: validComponents, canvasSize: canvasSize)
        let propertyInstructions = LayoutDescriptor.generatePropertyInstructions(for: validComponents)
        
        let designSystemInstructions = getDesignSystemInstructions()
        
        // Build explicit component list for AI
        let explicitComponentList = validComponents.enumerated().map { (index, comp) in
            return "Component \(index + 1): **\(comp.type.description.uppercased())** (position: \(Int(comp.rect.midX)), \(Int(comp.rect.midY)), size: \(Int(comp.rect.width))×\(Int(comp.rect.height)))"
        }.joined(separator: "\n")
        
        let prompt = """
        Create a clean, production-ready HTML page with embedded CSS for this UI layout:
        
        **Canvas:** \(Int(canvasSize.width))×\(Int(canvasSize.height))px
        **Components:** \(validComponents.count) total
        
        \(explicitComponentList)
        
        \(designSystemInstructions)
        
        **CRITICAL REQUIREMENTS:**
        - Create ONLY the exact HTML elements for each component type listed above
        - Use realistic, professional content (no "Lorem ipsum" or placeholder text)
        - Generate a complete, clean HTML page that looks production-ready
        - Include NO development comments, annotations, or debug information in the HTML
        - Make it look like a real website that users would actually see
        - Ensure all CSS is embedded in <style> tags in the <head>
        - Use proper semantic HTML and accessible markup
        
        **Component Type Mappings:**
        icon → SVG or icon font, button → <button>, navbar → <nav>, label → text element, image → <img>, form control → <input>/<textarea>, dropdown → <select>, alert → notification div, badge → status span, table → <table>, modal → dialog div, well → container div, carousel → slider div, progress bar → progress element, pagination → page nav, tab → tab nav, breadcrumb → breadcrumb nav, tooltip → tooltip div, thumbnail → small image, media object → card div, list group → <ul> list
        
        Output ONLY the complete HTML file - no explanations, no markdown, no comments.
        """
        
        ChatGPTService.shared.generateCode(prompt: prompt, model: selectedModel) { result in
            DispatchQueue.main.async {
                self.isGeneratingCode = false
                
                switch result {
                case .success(let code):
                    print("✅ Code generation successful")
                    // Clean the generated code for production preview
                    self.generatedCode = self.cleanGeneratedCode(code)
                    
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
    
    // MARK: - Code Cleaning for Production Preview
    
    private func cleanGeneratedCode(_ code: String) -> String {
        var cleanedCode = code
        
        // Remove any markdown code block markers that might have slipped through
        cleanedCode = cleanedCode.replacingOccurrences(of: "```html", with: "")
        cleanedCode = cleanedCode.replacingOccurrences(of: "```css", with: "")
        cleanedCode = cleanedCode.replacingOccurrences(of: "```", with: "")
        
        // Remove development comments from HTML
        cleanedCode = cleanedCode.replacingOccurrences(of: "<!-- DEBUG:", with: "<!--")
        cleanedCode = cleanedCode.replacingOccurrences(of: "<!-- Component:", with: "<!--")
        cleanedCode = cleanedCode.replacingOccurrences(of: "<!-- TODO:", with: "<!--")
        cleanedCode = cleanedCode.replacingOccurrences(of: "<!-- NOTE:", with: "<!--")
        cleanedCode = cleanedCode.replacingOccurrences(of: "<!-- INSTRUCTION:", with: "<!--")
        
        // Remove any CSS comments with development info
        let cssCommentPattern = "/\\*\\s*(DEBUG|TODO|NOTE|INSTRUCTION|Component)[^*]*\\*/"
        cleanedCode = cleanedCode.replacingOccurrences(of: cssCommentPattern, 
                                                      with: "", 
                                                      options: .regularExpression)
        
        // Remove any lines that look like development annotations
        let lines = cleanedCode.components(separatedBy: .newlines)
        let filteredLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Filter out lines that are clearly development annotations
            if trimmed.hasPrefix("<!-- Component") ||
               trimmed.hasPrefix("<!-- DEBUG") ||
               trimmed.hasPrefix("<!-- TODO") ||
               trimmed.hasPrefix("<!-- NOTE") ||
               trimmed.contains("Element 1:") ||
               trimmed.contains("Element 2:") ||
               trimmed.contains("Component 1:") ||
               trimmed.contains("Component 2:") {
                return false
            }
            
            return true
        }
        
        cleanedCode = filteredLines.joined(separator: "\n")
        
        // Clean up any excessive whitespace
        while cleanedCode.contains("\n\n\n") {
            cleanedCode = cleanedCode.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return cleanedCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Design System Instructions
    
    private func getDesignSystemInstructions() -> String {
        let libraryName = libraryManager.currentPack.name.lowercased()
        let colorScheme = libraryManager.currentPack.colorScheme
        
        if libraryName.contains("bootstrap") {
            return """
            - Use Bootstrap 5.3 CSS framework (include CDN link in head)
            - Use Bootstrap classes: btn, btn-primary, navbar, nav, form-control, etc.
            - Use Bootstrap's grid system with container, row, col classes
            - Use Bootstrap components like cards, buttons, forms, navigation
            - Apply Bootstrap utility classes for spacing, colors, and layout
            - Primary color: \(colorScheme.primary), Secondary: \(colorScheme.secondary)
            """
        } else if libraryName.contains("tailwind") {
            return """
            - Use Tailwind CSS 3.x framework (include CDN link in head)
            - Use Tailwind utility classes: bg-blue-500, text-white, p-4, flex, etc.
            - Use Tailwind's responsive prefixes: sm:, md:, lg:, xl:
            - Use Tailwind component classes for buttons, forms, navigation
            - Apply Tailwind's modern color palette and spacing system
            - Primary color: \(colorScheme.primary), Secondary: \(colorScheme.secondary)
            """
        } else if libraryName.contains("material") {
            return """
            - Use Material Design 3 principles and components
            - Use Material UI CSS framework or custom Material Design styles
            - Apply Material Design elevation, typography, and spacing
            - Use Material Design color system and elevation shadows
            - Implement Material Design interaction patterns (ripples, transitions)
            - Primary color: \(colorScheme.primary), Secondary: \(colorScheme.secondary)
            """
        } else if libraryName.contains("ios") || libraryName.contains("human interface") {
            return """
            - Use iOS Human Interface Guidelines design patterns
            - Apply iOS-style typography, spacing, and visual hierarchy
            - Use iOS color system and SF Symbols where appropriate
            - Implement iOS-style navigation and interaction patterns
            - Use rounded corners, subtle shadows, and iOS visual elements
            - Primary color: \(colorScheme.primary), Secondary: \(colorScheme.secondary)
            """
        } else {
            return """
            - Use custom CSS with modern design patterns from \(libraryManager.currentPack.name)
            - Create responsive design with CSS Grid and Flexbox
            - Use CSS custom properties (variables) for colors and spacing
            - Apply modern typography and spacing conventions
            - Primary color: \(colorScheme.primary), Secondary: \(colorScheme.secondary), Accent: \(colorScheme.accent)
            """
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

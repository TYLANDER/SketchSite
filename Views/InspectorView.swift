import SwiftUI

struct InspectorView: View {
    @Binding var component: DetectedComponent
    @State private var label: String = ""
    @State private var textContent: String = ""
    @State private var width: CGFloat = 0
    @State private var height: CGFloat = 0
    @State private var type: UIComponentType = .label
    @State private var usePercentages: Bool = false
    @State private var selectedTab: InspectorTab = .basic
    
    // Canvas size for percentage calculations (passed from parent)
    var canvasSize: CGSize = UIScreen.main.bounds.size
    
    enum InspectorTab: String, CaseIterable {
        case basic = "Basic"
        case properties = "Properties"
        case text = "Text"
        case colors = "Colors"
        case navigation = "Navigation"
        
        var icon: String {
            switch self {
            case .basic: return "square.and.pencil"
            case .properties: return "slider.horizontal.3"
            case .text: return "textformat"
            case .colors: return "paintpalette"
            case .navigation: return "list.bullet"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            tabPicker
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                basicPropertiesView
                    .tag(InspectorTab.basic)
                
                advancedPropertiesView
                    .tag(InspectorTab.properties)
                
                textPropertiesView
                    .tag(InspectorTab.text)
                
                colorPropertiesView
                    .tag(InspectorTab.colors)
                
                navigationPropertiesView
                    .tag(InspectorTab.navigation)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onAppear {
            updateFromComponent()
        }
        .onChange(of: component.id) { _, _ in
            updateFromComponent()
            // Reset to basic tab if current tab is not available
            if !availableTabs.contains(selectedTab) {
                selectedTab = .basic
            }
        }
        .onChange(of: usePercentages) { oldValue, newValue in
            convertSizeUnits(toPercentages: newValue)
        }
    }
    
    // MARK: - Tab Picker
    
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(.regularMaterial)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var availableTabs: [InspectorTab] {
        var tabs: [InspectorTab] = [.basic]
        
        if !component.properties.booleanProperties.isEmpty ||
           !component.properties.instanceSwapProperties.isEmpty {
            tabs.append(.properties)
        }
        
        if !component.properties.enhancedTextProperties.isEmpty || componentSupportsText(type) {
            tabs.append(.text)
        }
        
        if !component.properties.colorProperties.isEmpty {
            tabs.append(.colors)
        }
        
        if !component.properties.navigationItemsProperties.isEmpty {
            tabs.append(.navigation)
        }
        
        return tabs
    }
    
    // MARK: - Basic Properties View
    
    private var basicPropertiesView: some View {
        Form {
            Section(header: Text("Component Type")) {
                Picker("Type", selection: $type) {
                    ForEach(UIComponentType.allCases, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: type) { oldValue, newValue in
                    component.type = .ui(newValue)
                    
                    // Reinitialize properties for the new component type
                    component.reinitializePropertiesForType()
                    
                    // Update text content with default for new type if current is empty
                    if textContent.isEmpty {
                        if let defaultText = DetectedComponent.defaultTextContent(for: .ui(newValue)) {
                            textContent = defaultText
                            component.textContent = defaultText
                        }
                    }
                }
            }
            
            Section(header: Text("Label")) {
                TextField("Component Label", text: $label, prompt: Text("Optional label"))
                    .onChange(of: label) { oldValue, newValue in
                        component.label = newValue.isEmpty ? nil : newValue
                    }
            }
            
            Section(header: sizeHeaderView) {
                // Size unit toggle
                Picker("Size Unit", selection: $usePercentages) {
                    Text("Pixels").tag(false)
                    Text("Percentages").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)
                
                // Width input
                HStack {
                    Text("Width")
                        .foregroundColor(.primary)
                    Spacer()
                    TextField("Width", value: $width, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text(usePercentages ? "%" : "px")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(width: 20)
                }
                
                // Height input
                HStack {
                    Text("Height")
                        .foregroundColor(.primary)
                    Spacer()
                    TextField("Height", value: $height, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text(usePercentages ? "%" : "px")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(width: 20)
                }
                
                // Apply button
                Button(action: applySizeChanges) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Apply Size Changes")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(width <= 0 || height <= 0)
            }
            
            Section(header: Text("Position")) {
                HStack {
                    Text("X Position")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(component.rect.minX)) px")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Y Position")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(component.rect.minY)) px")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
    
    // MARK: - Advanced Properties View
    
    private var advancedPropertiesView: some View {
        Form {
            // Boolean Properties
            if !component.properties.booleanProperties.isEmpty {
                Section(header: Text("Boolean Properties")) {
                    ForEach(component.properties.booleanProperties.indices, id: \.self) { index in
                        BooleanPropertyRow(
                            property: $component.properties.booleanProperties[index]
                        )
                    }
                }
            }
            
            // Instance Swap Properties
            if !component.properties.instanceSwapProperties.isEmpty {
                Section(header: Text("Instance Swap")) {
                    ForEach(component.properties.instanceSwapProperties.indices, id: \.self) { index in
                        InstanceSwapPropertyRow(
                            property: $component.properties.instanceSwapProperties[index]
                        )
                    }
                }
            }
            
            if component.properties.booleanProperties.isEmpty && component.properties.instanceSwapProperties.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Advanced Properties")
                            .font(.headline)
                        Text("This component type doesn't have advanced properties available.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - Text Properties View
    
    private var textPropertiesView: some View {
        Form {
            // Basic text content (legacy support)
            if componentSupportsText(type) {
                Section(header: Text("Basic Text")) {
                    TextField("Text Content", text: $textContent, prompt: Text("Enter display text"))
                        .onChange(of: textContent) { oldValue, newValue in
                            component.textContent = newValue.isEmpty ? nil : newValue
                        }
                }
            }
            
            // Enhanced Text Properties
            if !component.properties.enhancedTextProperties.isEmpty {
                Section(header: Text("Enhanced Text Properties")) {
                    ForEach(component.properties.enhancedTextProperties.indices, id: \.self) { index in
                        EnhancedTextPropertyRow(
                            property: $component.properties.enhancedTextProperties[index]
                        )
                    }
                }
            }
            
            if !componentSupportsText(type) && component.properties.enhancedTextProperties.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "textformat")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Text Properties")
                            .font(.headline)
                        Text("This component type doesn't support text content.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - Color Properties View
    
    private var colorPropertiesView: some View {
        Form {
            if !component.properties.colorProperties.isEmpty {
                ForEach(component.properties.colorProperties.indices, id: \.self) { index in
                    Section(header: Text(component.properties.colorProperties[index].name)) {
                        ColorPropertyRow(
                            property: $component.properties.colorProperties[index]
                        )
                    }
                }
            } else {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "paintpalette")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Color Properties")
                            .font(.headline)
                        Text("This component type doesn't have color properties available.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - Navigation Properties View
    
    private var navigationPropertiesView: some View {
        Form {
            if !component.properties.navigationItemsProperties.isEmpty {
                ForEach(component.properties.navigationItemsProperties.indices, id: \.self) { navPropIndex in
                    Section(header: Text(component.properties.navigationItemsProperties[navPropIndex].name)) {
                        NavigationItemsPropertyRow(
                            property: $component.properties.navigationItemsProperties[navPropIndex]
                        )
                    }
                }
            } else {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Navigation Properties")
                            .font(.headline)
                        Text("This component type doesn't have navigation properties available.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    // MARK: - Helper Views and Methods
    
    private var sizeHeaderView: some View {
        HStack {
            Text("Size")
            Spacer()
            Image(systemName: usePercentages ? "percent" : "ruler")
                .foregroundColor(.blue)
                .font(.caption)
        }
    }
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = usePercentages ? 1 : 0
        return formatter
    }
    
    private func updateFromComponent() {
        label = component.label ?? ""
        textContent = component.textContent ?? ""
        if case let .ui(t) = component.type { 
            type = t 
        } else {
            type = UIComponentType.allCases.first ?? .label
        }
        
        // Initialize with pixel values
        width = component.rect.width
        height = component.rect.height
        usePercentages = false
    }
    
    private func convertSizeUnits(toPercentages: Bool) {
        if toPercentages {
            // Convert pixels to percentages
            width = (component.rect.width / canvasSize.width) * 100
            height = (component.rect.height / canvasSize.height) * 100
        } else {
            // Convert percentages to pixels
            width = component.rect.width
            height = component.rect.height
        }
    }
    
    private func applySizeChanges() {
        let newWidth: CGFloat
        let newHeight: CGFloat
        
        if usePercentages {
            // Convert percentages to pixels
            newWidth = (width / 100) * canvasSize.width
            newHeight = (height / 100) * canvasSize.height
        } else {
            // Use pixel values directly
            newWidth = width
            newHeight = height
        }
        
        // Ensure minimum size
        let minSize: CGFloat = 20
        let clampedWidth = max(minSize, newWidth)
        let clampedHeight = max(minSize, newHeight)
        
        // Update component rect while maintaining position
        component.rect = CGRect(
            x: component.rect.origin.x,
            y: component.rect.origin.y,
            width: clampedWidth,
            height: clampedHeight
        )
        
        // Update the displayed values to reflect any clamping
        if usePercentages {
            width = (clampedWidth / canvasSize.width) * 100
            height = (clampedHeight / canvasSize.height) * 100
        } else {
            width = clampedWidth
            height = clampedHeight
        }
        
        print("📐 Applied size changes: \(Int(clampedWidth))×\(Int(clampedHeight)) px")
        
        // Haptic feedback for successful change
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Determines if a component type supports editable text content
    private func componentSupportsText(_ componentType: UIComponentType) -> Bool {
        switch componentType {
        case .button, .label, .navbar, .tab, .breadcrumb, .badge, .alert, 
             .formControl, .textarea, .dropdown, .tooltip, .pagination, .modal, .well:
            return true
        case .image, .icon, .thumbnail, .carousel, .table, .progressBar, 
             .form, .listGroup, .mediaObject, .buttonGroup, .navs, .collapse:
            return false
        }
    }
}

// MARK: - Property Row Views

struct BooleanPropertyRow: View {
    @Binding var property: BooleanProperty
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(property.name)
                    .font(.body)
                if !property.affectedLayers.isEmpty {
                    Text("Affects: \(property.affectedLayers.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $property.currentValue)
                .labelsHidden()
        }
    }
}

struct InstanceSwapPropertyRow: View {
    @Binding var property: InstanceSwapProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(property.name)
                .font(.headline)
            
            Picker("Options", selection: $property.currentOption) {
                ForEach(property.availableOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct EnhancedTextPropertyRow: View {
    @Binding var property: EnhancedTextProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(property.name)
                .font(.headline)
            
            TextField("Text Content", text: $property.content, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...3)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Style")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Style", selection: $property.style) {
                        ForEach(EnhancedTextProperty.TextStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alignment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Alignment", selection: $property.alignment) {
                        ForEach(EnhancedTextProperty.TextAlignment.allCases, id: \.self) { alignment in
                            Text(alignment.displayName).tag(alignment)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
}

struct ColorPropertyRow: View {
    @Binding var property: ColorProperty
    @State private var showingColorPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Semantic Role")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Role", selection: $property.semanticRole) {
                    ForEach(ColorProperty.ColorRole.allCases, id: \.self) { role in
                        Text(role.displayName).tag(role)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                Text("Color Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Mode", selection: $property.currentMode) {
                    ForEach(ColorProperty.ColorMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Color preview and editor
            HStack {
                Text("Current Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showingColorPicker = true }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: property.currentColor) ?? .gray)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.secondary, lineWidth: 1)
                            )
                        
                        Text(property.currentColor)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ProfessionalColorPickerView(property: $property)
        }
    }
}



// MARK: - Color Extensions

struct NavigationItemsPropertyRow: View {
    @Binding var property: NavigationItemsProperty
    @State private var newItemText: String = ""
    @State private var showingAddItem = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current navigation items
            if !property.items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Navigation Items (\(property.items.count)/\(property.maxItems))")
                        .font(.headline)
                    
                    ForEach(property.items.indices, id: \.self) { index in
                        NavigationItemRow(
                            item: $property.items[index],
                            onDelete: {
                                property.removeItem(withId: property.items[index].id)
                            }
                        )
                    }
                }
            }
            
            // Add new item section
            VStack(alignment: .leading, spacing: 8) {
                if showingAddItem {
                    VStack(spacing: 8) {
                        TextField("Navigation item text", text: $newItemText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Button("Cancel") {
                                showingAddItem = false
                                newItemText = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Add Item") {
                                addNewItem()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                } else {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Navigation Item")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(property.items.count >= property.maxItems)
                }
            }
            
            if property.items.count >= property.maxItems {
                Text("Maximum \(property.maxItems) navigation items allowed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func addNewItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let newItem = NavigationItem(text: trimmedText, isActive: false)
        property.addItem(newItem)
        
        newItemText = ""
        showingAddItem = false
    }
}

struct NavigationItemRow: View {
    @Binding var item: NavigationItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Item text", text: $item.text)
                    .font(.body)
                
                HStack {
                    Toggle("Active", isOn: $item.isActive)
                        .font(.caption)
                    
                    Spacer()
                }
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
} 
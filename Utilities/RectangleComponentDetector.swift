import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Component Properties

/// Represents a single navigation item in a navbar
public struct NavigationItem: Identifiable, Codable, Hashable {
    public let id = UUID()
    public var text: String
    public var isActive: Bool
    public var icon: String?
    
    public init(text: String, isActive: Bool = false, icon: String? = nil) {
        self.text = text
        self.isActive = isActive
        self.icon = icon
    }
}

/// Navigation items property for managing navbar navigation elements
public struct NavigationItemsProperty: Identifiable, Codable, Hashable {
    public let id = UUID()
    public var name: String
    public var items: [NavigationItem]
    public var maxItems: Int
    
    public init(name: String, items: [NavigationItem] = [], maxItems: Int = 6) {
        self.name = name
        self.items = items
        self.maxItems = maxItems
    }
    
    public mutating func addItem(_ item: NavigationItem) {
        if items.count < maxItems {
            items.append(item)
        }
    }
    
    public mutating func removeItem(withId id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    public mutating func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    public var itemsText: String {
        return items.map { $0.text }.joined(separator: " | ")
    }
}

/// Boolean property for toggling visibility and states
public struct BooleanProperty: Identifiable, Codable, Hashable {
    public let id = UUID()
    public var name: String
    public var defaultValue: Bool
    public var currentValue: Bool
    public var affectedLayers: [String] // Layer IDs that this property controls
    
    public init(name: String, defaultValue: Bool, affectedLayers: [String] = []) {
        self.name = name
        self.defaultValue = defaultValue
        self.currentValue = defaultValue
        self.affectedLayers = affectedLayers
    }
}

/// Instance swap property for replacing nested components
public struct InstanceSwapProperty: Identifiable, Codable, Hashable {
    public let id = UUID()
    public var name: String
    public var availableOptions: [String] // Available component options
    public var defaultOption: String
    public var currentOption: String
    
    public init(name: String, availableOptions: [String], defaultOption: String) {
        self.name = name
        self.availableOptions = availableOptions
        self.defaultOption = defaultOption
        self.currentOption = defaultOption
    }
}

/// Enhanced text property for advanced text customization
public struct EnhancedTextProperty: Identifiable, Codable, Hashable {
    public let id = UUID()
    public var name: String
    public var content: String
    public var style: TextStyle
    public var alignment: TextAlignment
    
    public enum TextStyle: String, CaseIterable, Codable {
        case regular = "regular"
        case bold = "bold"
        case italic = "italic"
        case light = "light"
        
        public var displayName: String {
            switch self {
            case .regular: return "Regular"
            case .bold: return "Bold"
            case .italic: return "Italic"
            case .light: return "Light"
            }
        }
    }
    
    public enum TextAlignment: String, CaseIterable, Codable {
        case left = "left"
        case center = "center"
        case right = "right"
        
        public var displayName: String {
            switch self {
            case .left: return "Left"
            case .center: return "Center"
            case .right: return "Right"
            }
        }
    }
    
    public init(name: String, content: String, style: TextStyle = .regular, alignment: TextAlignment = .left) {
        self.name = name
        self.content = content
        self.style = style
        self.alignment = alignment
    }
}

/// Color property for theme-aware color customization
public struct ColorProperty: Identifiable, Codable, Hashable {
    public let id = UUID()
    public var name: String
    public var colorScheme: [String: String] // "light": hex, "dark": hex
    public var semanticRole: ColorRole
    public var currentMode: ColorMode
    
    public enum ColorRole: String, CaseIterable, Codable {
        case primary = "primary"
        case secondary = "secondary"
        case accent = "accent"
        case success = "success"
        case warning = "warning"
        case error = "error"
        case info = "info"
        case custom = "custom"
        
        public var displayName: String {
            switch self {
            case .primary: return "Primary"
            case .secondary: return "Secondary"
            case .accent: return "Accent"
            case .success: return "Success"
            case .warning: return "Warning"
            case .error: return "Error"
            case .info: return "Info"
            case .custom: return "Custom"
            }
        }
        
        public var defaultColor: String {
            switch self {
            case .primary: return "#007AFF"
            case .secondary: return "#8E8E93"
            case .accent: return "#FF9500"
            case .success: return "#34C759"
            case .warning: return "#FF9500"
            case .error: return "#FF3B30"
            case .info: return "#5AC8FA"
            case .custom: return "#000000"
            }
        }
    }
    
    public enum ColorMode: String, CaseIterable, Codable {
        case light = "light"
        case dark = "dark"
        case auto = "auto"
        
        public var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .auto: return "Auto"
            }
        }
    }
    
    public init(name: String, semanticRole: ColorRole, currentMode: ColorMode = .auto) {
        self.name = name
        self.semanticRole = semanticRole
        self.currentMode = currentMode
        self.colorScheme = [
            "light": semanticRole.defaultColor,
            "dark": semanticRole.defaultColor
        ]
    }
    
    public var currentColor: String {
        switch currentMode {
        case .light: return colorScheme["light"] ?? semanticRole.defaultColor
        case .dark: return colorScheme["dark"] ?? semanticRole.defaultColor
        case .auto: return colorScheme["light"] ?? semanticRole.defaultColor // Default to light for now
        }
    }
}

// MARK: - Component Properties Container

/// Container for all component properties
public struct ComponentProperties: Codable, Hashable {
    public var booleanProperties: [BooleanProperty] = []
    public var instanceSwapProperties: [InstanceSwapProperty] = []
    public var enhancedTextProperties: [EnhancedTextProperty] = []
    public var colorProperties: [ColorProperty] = []
    public var navigationItemsProperties: [NavigationItemsProperty] = []
    
    public init() {}
    
    // Helper methods for property management
    public mutating func addBooleanProperty(_ property: BooleanProperty) {
        booleanProperties.append(property)
    }
    
    public mutating func addInstanceSwapProperty(_ property: InstanceSwapProperty) {
        instanceSwapProperties.append(property)
    }
    
    public mutating func addEnhancedTextProperty(_ property: EnhancedTextProperty) {
        enhancedTextProperties.append(property)
    }
    
    public mutating func addColorProperty(_ property: ColorProperty) {
        colorProperties.append(property)
    }
    
    public mutating func addNavigationItemsProperty(_ property: NavigationItemsProperty) {
        navigationItemsProperties.append(property)
    }
    
    public func getBooleanProperty(named name: String) -> BooleanProperty? {
        return booleanProperties.first { $0.name == name }
    }
    
    public func getInstanceSwapProperty(named name: String) -> InstanceSwapProperty? {
        return instanceSwapProperties.first { $0.name == name }
    }
    
    public func getEnhancedTextProperty(named name: String) -> EnhancedTextProperty? {
        return enhancedTextProperties.first { $0.name == name }
    }
    
    public func getColorProperty(named name: String) -> ColorProperty? {
        return colorProperties.first { $0.name == name }
    }
    
    public func getNavigationItemsProperty(named name: String) -> NavigationItemsProperty? {
        return navigationItemsProperties.first { $0.name == name }
    }
}

// MARK: - DetectedComponent

/// Represents a detected UI component or group on the canvas.
public struct DetectedComponent: Identifiable, Hashable, Codable {
    public let id = UUID()                // Unique identifier for SwiftUI/ForEach
    public var rect: CGRect               // The bounding box of the component
    public var type: DetectedComponentType// The inferred type (single or group)
    public var label: String?             // Optional user annotation label
    public var textContent: String?       // Editable text content for components that display text
    public var properties: ComponentProperties // Advanced component properties
    
    // Custom initializer to maintain immutable ID
    public init(rect: CGRect, type: DetectedComponentType, label: String?, textContent: String? = nil) {
        self.rect = rect
        self.type = type
        self.label = label
        self.textContent = textContent ?? DetectedComponent.defaultTextContent(for: type)
        self.properties = ComponentProperties()
        
        // Initialize default properties based on component type
        self.initializeDefaultProperties()
    }
    
    // Initialize default properties based on component type
    private mutating func initializeDefaultProperties() {
        switch type {
        case .ui(let uiType):
            initializeUIComponentProperties(for: uiType)
        case .group(let groupType):
            initializeGroupComponentProperties(for: groupType)
        case .unknown:
            break
        }
    }
    
    private mutating func initializeUIComponentProperties(for uiType: UIComponentType) {
        switch uiType {
        // MARK: - Basic Interactive Components
        case .button:
            properties.addBooleanProperty(BooleanProperty(name: "Has Icon", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Is Disabled", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Loading State", defaultValue: false))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Button Style", availableOptions: ["Primary", "Secondary", "Outline", "Ghost"], defaultOption: "Primary"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large"], defaultOption: "Medium"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Icon Type", availableOptions: ["arrow.right", "plus", "star", "heart", "download", "share"], defaultOption: "arrow.right"))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Button Text", content: textContent ?? "Button", style: .bold, alignment: .center))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .secondary))
            
        case .buttonGroup:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Orientation", availableOptions: ["Horizontal", "Vertical"], defaultOption: "Horizontal"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Segmented", "Separate", "Connected"], defaultOption: "Connected"))
            properties.addBooleanProperty(BooleanProperty(name: "Equal Width", defaultValue: true))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .primary))
            
        // MARK: - Text & Content Components  
        case .label:
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Text Content", content: textContent ?? "Label", style: .regular, alignment: .left))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Typography", availableOptions: ["Body", "Heading", "Caption", "Subtitle"], defaultOption: "Body"))
            properties.addBooleanProperty(BooleanProperty(name: "Truncate", defaultValue: false))
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .primary))
            
        case .badge:
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Badge Text", content: textContent ?? "Badge", style: .bold, alignment: .center))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Solid", "Outline", "Pill"], defaultOption: "Solid"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large"], defaultOption: "Medium"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Variant", availableOptions: ["Primary", "Success", "Warning", "Error", "Info"], defaultOption: "Primary"))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .secondary))
            
        case .icon:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Icon Type", availableOptions: ["star", "heart", "plus", "minus", "home", "user", "settings", "search"], defaultOption: "star"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large", "XLarge"], defaultOption: "Medium"))
            properties.addBooleanProperty(BooleanProperty(name: "Filled", defaultValue: false))
            properties.addColorProperty(ColorProperty(name: "Icon Color", semanticRole: .primary))
            
        // MARK: - Form Components
        case .formControl:
            properties.addBooleanProperty(BooleanProperty(name: "Is Required", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Has Error", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Is Disabled", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Read Only", defaultValue: false))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Placeholder Text", content: "Enter text", style: .regular, alignment: .left))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Label Text", content: "Field Label", style: .regular, alignment: .left))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Input Type", availableOptions: ["Text", "Email", "Password", "Number", "Tel", "URL"], defaultOption: "Text"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large"], defaultOption: "Medium"))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            properties.addColorProperty(ColorProperty(name: "Focus Color", semanticRole: .primary))
            
        case .dropdown:
            properties.addBooleanProperty(BooleanProperty(name: "Searchable", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Multi Select", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Is Disabled", defaultValue: false))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Placeholder Text", content: "Select option...", style: .regular, alignment: .left))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Standard", "Borderless", "Filled"], defaultOption: "Standard"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large"], defaultOption: "Medium"))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .form:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Layout", availableOptions: ["Vertical", "Horizontal", "Inline"], defaultOption: "Vertical"))
            properties.addBooleanProperty(BooleanProperty(name: "Show Validation", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Required Indicators", defaultValue: true))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .secondary))
            
        // MARK: - Navigation Components
        case .navbar:
            properties.addBooleanProperty(BooleanProperty(name: "Show Logo", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Sticky", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Show Search", defaultValue: false))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Position", availableOptions: ["Top", "Bottom", "Sidebar"], defaultOption: "Top"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Light", "Dark", "Transparent"], defaultOption: "Light"))
            let navItems = NavigationItemsProperty(name: "Navigation Items", items: [
                NavigationItem(text: "Home", isActive: true), NavigationItem(text: "About", isActive: false),
                NavigationItem(text: "Services", isActive: false), NavigationItem(text: "Contact", isActive: false)
            ], maxItems: 8)
            properties.addNavigationItemsProperty(navItems)
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .secondary))
            
        case .navs:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Tabs", "Pills", "Underline"], defaultOption: "Tabs"))
            properties.addBooleanProperty(BooleanProperty(name: "Justify Content", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Vertical", defaultValue: false))
            let navItems = NavigationItemsProperty(name: "Navigation Items", items: [
                NavigationItem(text: "Tab 1", isActive: true), NavigationItem(text: "Tab 2", isActive: false),
                NavigationItem(text: "Tab 3", isActive: false)
            ], maxItems: 6)
            properties.addNavigationItemsProperty(navItems)
            properties.addColorProperty(ColorProperty(name: "Active Color", semanticRole: .primary))
            
        case .tab:
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Tab Label", content: textContent ?? "Tab", style: .regular, alignment: .center))
            properties.addBooleanProperty(BooleanProperty(name: "Is Active", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Is Disabled", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Has Icon", defaultValue: false))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Icon Type", availableOptions: ["home", "user", "settings", "mail", "bell"], defaultOption: "home"))
            properties.addColorProperty(ColorProperty(name: "Active Color", semanticRole: .primary))
            
        case .breadcrumb:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Separator", availableOptions: ["Chevron", "Slash", "Arrow", "Dot"], defaultOption: "Chevron"))
            properties.addBooleanProperty(BooleanProperty(name: "Show Home", defaultValue: true))
            let breadcrumbItems = NavigationItemsProperty(name: "Breadcrumb Items", items: [
                NavigationItem(text: "Home", isActive: false), NavigationItem(text: "Category", isActive: false),
                NavigationItem(text: "Current", isActive: true)
            ], maxItems: 5)
            properties.addNavigationItemsProperty(breadcrumbItems)
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .secondary))
            properties.addColorProperty(ColorProperty(name: "Active Color", semanticRole: .primary))
            
        case .pagination:
            properties.addBooleanProperty(BooleanProperty(name: "Show Numbers", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Show First/Last", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Show Previous/Next", defaultValue: true))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large"], defaultOption: "Medium"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Standard", "Rounded", "Outline"], defaultOption: "Standard"))
            properties.addColorProperty(ColorProperty(name: "Active Color", semanticRole: .primary))
            
        // MARK: - Media Components
        case .image:
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Alt Text", content: "Image description", style: .regular, alignment: .left))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Aspect Ratio", availableOptions: ["Square", "16:9", "4:3", "3:2", "Auto"], defaultOption: "Auto"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Object Fit", availableOptions: ["Cover", "Contain", "Fill", "Scale Down"], defaultOption: "Cover"))
            properties.addBooleanProperty(BooleanProperty(name: "Responsive", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Lazy Load", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Has Border", defaultValue: false))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .thumbnail:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large"], defaultOption: "Medium"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Shape", availableOptions: ["Square", "Circle", "Rounded"], defaultOption: "Rounded"))
            properties.addBooleanProperty(BooleanProperty(name: "Has Hover Effect", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Has Border", defaultValue: false))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .carousel:
            properties.addBooleanProperty(BooleanProperty(name: "Auto Play", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Show Dots", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Show Arrows", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Infinite Loop", defaultValue: true))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Transition", availableOptions: ["Slide", "Fade", "Zoom"], defaultOption: "Slide"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Slides Visible", availableOptions: ["1", "2", "3", "4"], defaultOption: "1"))
            properties.addColorProperty(ColorProperty(name: "Indicator Color", semanticRole: .primary))
            
        // MARK: - Layout Components  
        case .mediaObject:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Image Position", availableOptions: ["Left", "Right", "Top"], defaultOption: "Left"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Alignment", availableOptions: ["Top", "Center", "Bottom"], defaultOption: "Top"))
            properties.addBooleanProperty(BooleanProperty(name: "Has Shadow", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Has Border", defaultValue: false))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Title Text", content: "Card Title", style: .bold, alignment: .left))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Content Text", content: "Card content description", style: .regular, alignment: .left))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .secondary))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .listGroup:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Standard", "Flush", "Horizontal"], defaultOption: "Standard"))
            properties.addBooleanProperty(BooleanProperty(name: "Numbered", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Selectable", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Show Dividers", defaultValue: true))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .secondary))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .table:
            properties.addBooleanProperty(BooleanProperty(name: "Striped Rows", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Bordered", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Hover Effects", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Responsive", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Sortable Headers", defaultValue: false))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Compact", "Standard", "Spacious"], defaultOption: "Standard"))
            properties.addColorProperty(ColorProperty(name: "Header Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .well:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large"], defaultOption: "Medium"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Standard", "Bordered", "Shadow"], defaultOption: "Standard"))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Content Text", content: textContent ?? "Well content", style: .regular, alignment: .left))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .secondary))
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .collapse:
            properties.addBooleanProperty(BooleanProperty(name: "Is Expanded", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Show Toggle Icon", defaultValue: true))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Animation", availableOptions: ["Slide", "Fade", "None"], defaultOption: "Slide"))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Header Text", content: "Toggle Header", style: .bold, alignment: .left))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Content Text", content: "Collapsible content", style: .regular, alignment: .left))
            properties.addColorProperty(ColorProperty(name: "Header Color", semanticRole: .primary))
            
        // MARK: - Feedback Components
        case .alert:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Type", availableOptions: ["Info", "Success", "Warning", "Error"], defaultOption: "Info"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Filled", "Outlined", "Light"], defaultOption: "Light"))
            properties.addBooleanProperty(BooleanProperty(name: "Show Icon", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Dismissible", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Has Actions", defaultValue: false))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Title Text", content: "Alert Title", style: .bold, alignment: .left))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Message Text", content: textContent ?? "Alert message", style: .regular, alignment: .left))
            properties.addColorProperty(ColorProperty(name: "Alert Color", semanticRole: .info))
            
        case .modal:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Size", availableOptions: ["Small", "Medium", "Large", "Extra Large"], defaultOption: "Medium"))
            properties.addBooleanProperty(BooleanProperty(name: "Has Backdrop", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Dismissible", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Has Header", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Has Footer", defaultValue: true))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Title Text", content: "Modal Title", style: .bold, alignment: .left))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .secondary))
            properties.addColorProperty(ColorProperty(name: "Header Color", semanticRole: .primary))
            
        case .tooltip:
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Position", availableOptions: ["Top", "Bottom", "Left", "Right"], defaultOption: "Top"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Trigger", availableOptions: ["Hover", "Click", "Focus"], defaultOption: "Hover"))
            properties.addBooleanProperty(BooleanProperty(name: "Show Arrow", defaultValue: true))
            properties.addEnhancedTextProperty(EnhancedTextProperty(name: "Tooltip Text", content: textContent ?? "Tooltip content", style: .regular, alignment: .center))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .secondary))
            
        case .progressBar:
            properties.addBooleanProperty(BooleanProperty(name: "Animated", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Striped", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Show Label", defaultValue: true))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Style", availableOptions: ["Standard", "Thin", "Thick"], defaultOption: "Standard"))
            properties.addInstanceSwapProperty(InstanceSwapProperty(name: "Variant", availableOptions: ["Primary", "Success", "Warning", "Error"], defaultOption: "Primary"))
            properties.addColorProperty(ColorProperty(name: "Progress Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .secondary))
        }
    }
    
    private mutating func initializeGroupComponentProperties(for groupType: GroupType) {
        // Group-specific properties
        properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .secondary))
        
        switch groupType {
        case .navbar:
            properties.addBooleanProperty(BooleanProperty(name: "Show Logo", defaultValue: true))
            properties.addInstanceSwapProperty(InstanceSwapProperty(
                name: "Navigation Style",
                availableOptions: ["Fixed", "Sticky", "Static"],
                defaultOption: "Fixed"
            ))
            
            // Add default navigation items
            let defaultNavItems = NavigationItemsProperty(
                name: "Navigation Items",
                items: [
                    NavigationItem(text: "Home", isActive: true),
                    NavigationItem(text: "About", isActive: false),
                    NavigationItem(text: "Services", isActive: false),
                    NavigationItem(text: "Contact", isActive: false)
                ],
                maxItems: 6
            )
            properties.addNavigationItemsProperty(defaultNavItems)
            
        case .buttonGroup:
            properties.addInstanceSwapProperty(InstanceSwapProperty(
                name: "Orientation",
                availableOptions: ["Horizontal", "Vertical"],
                defaultOption: "Horizontal"
            ))
            
        default:
            break
        }
    }
    
    // Helper function to check if component type supports text
    private func componentSupportsText(_ componentType: UIComponentType) -> Bool {
        switch componentType {
        case .button, .label, .navbar, .tab, .breadcrumb, .badge, .alert, 
             .formControl, .dropdown, .tooltip, .pagination, .modal, .well:
            return true
        case .image, .icon, .thumbnail, .carousel, .table, .progressBar, 
             .form, .listGroup, .mediaObject, .buttonGroup, .navs, .collapse:
            return false
        }
    }
    
    // Helper function to provide default text content based on component type
    public static func defaultTextContent(for type: DetectedComponentType) -> String? {
        switch type {
        case .ui(let uiType):
            switch uiType {
            case .button: return "Button"
            case .label: return "Label"
            case .navbar: return "Navigation"
            case .tab: return "Tab"
            case .breadcrumb: return "Home > Page"
            case .badge: return "Badge"
            case .alert: return "Alert Message"
            case .formControl: return "Enter text"
            case .dropdown: return "Select option"
            case .tooltip: return "Tooltip"
            case .pagination: return "1 2 3"
            case .modal: return "Modal Title"
            default: return nil
            }
        case .group(let groupType):
            switch groupType {
            case .navbar: return "Navigation"
            case .buttonGroup: return "Button Group"
            case .formFieldGroup: return "Form Fields"
            default: return nil
            }
        case .unknown: return nil
        }
    }
}



// MARK: - RectangleComponentDetector

/// Detects and classifies UI components from rectangles and annotations.
public class RectangleComponentDetector {
    /// Main API: detects components from rectangles and optional annotations.
    /// - Parameters:
    ///   - rects: Array of CGRects representing detected rectangles.
    ///   - annotations: Optional dictionary of annotation labels to CGRects.
    ///   - canvasSize: The size of the canvas for relative calculations.
    /// - Returns: Array of DetectedComponent with inferred types and labels.
    public static func detectComponents(
        rects: [CGRect],
        annotations: [String: CGRect] = [:],
        canvasSize: CGSize
    ) -> [DetectedComponent] {
        // 1. Filter out rectangles that are too small or have poor quality
        let filteredRects = filterQualityRectangles(rects, canvasSize: canvasSize)
        print("🔍 Filtered rectangles: \(rects.count) → \(filteredRects.count)")
        
        // 2. Group rectangles by proximity/size
        let groups = groupRectangles(filteredRects, canvasSize: canvasSize)
        var detected: [DetectedComponent] = []
        var usedRects = Set<CGRect>()
        
        // 3. For each group, infer type
        for group in groups {
            if group.count == 1 {
                let rect = group[0]
                let label = annotationLabel(for: rect, annotations: annotations)
                let type = inferType(for: rect, canvasSize: canvasSize, annotation: label)
                detected.append(DetectedComponent(rect: rect, type: .ui(type), label: label))
                usedRects.insert(rect)
            } else {
                // Grouped component (e.g. nav bar, card grid, button group)
                let groupType = inferGroupType(for: group, canvasSize: canvasSize)
                for rect in group {
                    let label = annotationLabel(for: rect, annotations: annotations)
                    detected.append(DetectedComponent(rect: rect, type: .group(groupType), label: label))
                    usedRects.insert(rect)
                }
            }
        }
        // 4. Any unused rects (not grouped)
        for rect in filteredRects where !usedRects.contains(rect) {
            let label = annotationLabel(for: rect, annotations: annotations)
            let type = inferType(for: rect, canvasSize: canvasSize, annotation: label)
            detected.append(DetectedComponent(rect: rect, type: .ui(type), label: label))
        }
        
        // 5. Resolve overlapping components to ensure all are accessible
        let resolvedComponents = resolveOverlappingComponents(detected, canvasSize: canvasSize)
        
        return resolvedComponents
    }
    
    // MARK: - Quality Filtering
    
    /// Filters out rectangles that are too small, have poor aspect ratios, or are likely noise.
    private static func filterQualityRectangles(_ rects: [CGRect], canvasSize: CGSize) -> [CGRect] {
        // Detect device type for adaptive filtering
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        return rects.filter { rect in
            // Adaptive minimum size thresholds based on device
            let (minWidthPercent, minHeightPercent, minAreaPercent) = isIPad ? 
                (0.02, 0.02, 0.001) :  // iPad: More lenient (2% width/height, 0.1% area)
                (0.04, 0.04, 0.002)    // iPhone: Slightly more restrictive (4% width/height, 0.2% area)
            
            let minWidth = canvasSize.width * minWidthPercent
            let minHeight = canvasSize.height * minHeightPercent  
            let minArea = canvasSize.width * canvasSize.height * minAreaPercent
            
            // Absolute minimum sizes (device-agnostic safety net)
            let absoluteMinSize: CGFloat = isIPad ? 15.0 : 10.0  // Minimum 15pt on iPad, 10pt on iPhone
            
            // Check minimum dimensions with both relative and absolute thresholds
            let effectiveMinWidth = max(minWidth, absoluteMinSize)
            let effectiveMinHeight = max(minHeight, absoluteMinSize)
            
            guard rect.width >= effectiveMinWidth && rect.height >= effectiveMinHeight else {
                print("  ❌ Filtered out small rect: \(rect) (min: \(effectiveMinWidth)×\(effectiveMinHeight))")
                return false
            }
            
            // Check minimum area
            guard rect.width * rect.height >= minArea else {
                print("  ❌ Filtered out small rect: \(rect) (insufficient area: \(rect.width * rect.height) < \(minArea))")
                return false
            }
            
            // More lenient aspect ratio for iPad Apple Pencil drawing
            let maxAspectRatio: CGFloat = isIPad ? 15.0 : 10.0
            let minAspectRatio: CGFloat = 1.0 / maxAspectRatio
            
            let aspectRatio = rect.width / rect.height
            guard aspectRatio >= minAspectRatio && aspectRatio <= maxAspectRatio else {
                print("  ❌ Filtered out rect with extreme aspect ratio: \(rect) (aspect: \(aspectRatio), allowed: \(minAspectRatio)-\(maxAspectRatio))")
                return false
            }
            
            // Check if rectangle is within canvas bounds (with generous tolerance for iPad)
            let tolerance: CGFloat = isIPad ? 20.0 : 10.0
            let canvasBounds = CGRect(x: -tolerance, y: -tolerance, 
                                    width: canvasSize.width + 2*tolerance, 
                                    height: canvasSize.height + 2*tolerance)
            guard canvasBounds.contains(rect) else {
                print("  ❌ Filtered out rect outside canvas: \(rect)")
                return false
            }
            
            print("  ✅ Keeping quality rect: \(rect) (device: \(isIPad ? "iPad" : "iPhone"))")
            return true
        }
    }
    
    // MARK: - Grouping

    /// Groups rectangles by proximity, alignment, and grid/row/column structure.
    private static func groupRectangles(_ rects: [CGRect], canvasSize: CGSize) -> [[CGRect]] {
        // Improved grouping: detect rows, columns, and grids
        var groups: [[CGRect]] = []
        var used = Set<Int>()
        let threshold: CGFloat = max(canvasSize.width, canvasSize.height) * 0.05 // 5% of canvas
        let alignThreshold: CGFloat = max(canvasSize.width, canvasSize.height) * 0.02 // 2% for alignment
        
        // 1. Try to group by rows (horizontal alignment)
        for (i, rect) in rects.enumerated() {
            if used.contains(i) { continue }
            var row = [rect]
            for (j, other) in rects.enumerated() where i != j && !used.contains(j) {
                // If minY is close and heights are similar, treat as same row
                if abs(rect.minY - other.minY) < alignThreshold && abs(rect.height - other.height) < threshold {
                    row.append(other)
                    used.insert(j)
                }
            }
            if row.count > 1 {
                used.insert(i)
                groups.append(row)
            }
        }
        // 2. Try to group by columns (vertical alignment)
        for (i, rect) in rects.enumerated() {
            if used.contains(i) { continue }
            var col = [rect]
            for (j, other) in rects.enumerated() where i != j && !used.contains(j) {
                if abs(rect.minX - other.minX) < alignThreshold && abs(rect.width - other.width) < threshold {
                    col.append(other)
                    used.insert(j)
                }
            }
            if col.count > 1 {
                used.insert(i)
                groups.append(col)
            }
        }
        // 3. Any remaining rects are singletons
        for (i, rect) in rects.enumerated() where !used.contains(i) {
            groups.append([rect])
        }
        return groups
    }

    /// Heuristically infers the UI component type for a single rectangle, using annotation hints if available.
    private static func inferType(for rect: CGRect, canvasSize: CGSize, annotation: String? = nil) -> UIComponentType {
        let aspect = rect.width / max(rect.height, 1)
        _ = rect.width * rect.height // Area calculation - currently unused but may be needed for future heuristics
        let relWidth = rect.width / canvasSize.width
        let relHeight = rect.height / canvasSize.height
        let label = annotation?.lowercased() ?? ""
        // Use annotation hints if present
        if label.contains("img") || label.contains("photo") || label.contains("avatar") {
            return .image
        } else if label.contains("icon") {
            return .icon
        } else if label.contains("btn") || label.contains("button") {
            return .button
        } else if label.contains("nav") {
            return .navbar
        } else if label.contains("input") || label.contains("field") || label.contains("form") {
            return .formControl
        } else if label.contains("card") {
            return .mediaObject
        } else if label.contains("list") {
            return .listGroup
        } else if label.contains("tab") {
            return .tab
        } else if label.contains("badge") {
            return .badge
        } else if label.contains("progress") {
            return .progressBar
        } else if label.contains("dropdown") {
            return .dropdown
        } else if label.contains("table") {
            return .table
        }
        // Heuristics for common UI types (fallback)
        if relWidth > 0.8 && relHeight < 0.15 {
            return .navbar
        } else if aspect > 3 && relHeight < 0.1 {
            return .buttonGroup
        } else if aspect > 1.5 && relHeight < 0.2 {
            return .button
        } else if aspect < 0.7 && relHeight > 0.2 {
            return .formControl
        } else if relWidth > 0.3 && relHeight > 0.3 {
            return .image
        } else {
            return .label
        }
    }

    /// Heuristically infers the group type for a set of rectangles.
    private static func inferGroupType(for group: [CGRect], canvasSize: CGSize) -> GroupType {
        // Heuristic: if group is wide and short, it's a navbar; if grid-like, card grid; if many small, button group
        _ = group.map { $0.width }.reduce(0, +) / CGFloat(group.count) // Average width - currently unused but may be needed for future heuristics
        _ = group.map { $0.height }.reduce(0, +) / CGFloat(group.count) // Average height - currently unused but may be needed for future heuristics
        let minX = group.map { $0.minX }.min() ?? 0
        let maxX = group.map { $0.maxX }.max() ?? 0
        let minY = group.map { $0.minY }.min() ?? 0
        let maxY = group.map { $0.maxY }.max() ?? 0
        let groupWidth = maxX - minX
        let groupHeight = maxY - minY
        let relGroupWidth = groupWidth / canvasSize.width
        let relGroupHeight = groupHeight / canvasSize.height
        if relGroupWidth > 0.8 && relGroupHeight < 0.15 {
            return .navbar
        } else if group.count >= 4 && relGroupWidth > 0.5 && relGroupHeight > 0.3 {
            return .cardGrid
        } else if group.count >= 2 && relGroupWidth > 0.3 && relGroupHeight < 0.2 {
            return .buttonGroup
        } else {
            return .formFieldGroup
        }
    }

    // MARK: - Annotation Matching

    /// Returns the label for a rectangle if an annotation overlaps or is close.
    private static func annotationLabel(for rect: CGRect, annotations: [String: CGRect]) -> String? {
        // Find annotation whose rect overlaps or is close
        for (label, annRect) in annotations {
            if rect.intersects(annRect) || rect.distance(to: annRect) < 20 {
                return label
            }
        }
        return nil
    }

    // MARK: - Overlapping Component Resolution

    /// Resolves overlapping components by offsetting them to ensure all are accessible.
    private static func resolveOverlappingComponents(_ components: [DetectedComponent], canvasSize: CGSize) -> [DetectedComponent] {
        guard components.count > 1 else { return components }
        
        var resolvedComponents: [DetectedComponent] = []
        let overlapThreshold: CGFloat = 0.7 // 70% overlap threshold
        
        for (i, component) in components.enumerated() {
            var adjustedComponent = component
            var hasOverlap = true
            var attempts = 0
            let maxAttempts = 5
            
            while hasOverlap && attempts < maxAttempts {
                hasOverlap = false
                
                // Check for significant overlap with already resolved components
                for resolvedComponent in resolvedComponents {
                    let intersection = adjustedComponent.rect.intersection(resolvedComponent.rect)
                    let overlapArea = intersection.width * intersection.height
                    let componentArea = adjustedComponent.rect.width * adjustedComponent.rect.height
                    let overlapRatio = overlapArea / componentArea
                    
                    if overlapRatio > overlapThreshold {
                        hasOverlap = true
                        
                        // Calculate offset direction based on relative positions
                        let dx = adjustedComponent.rect.midX - resolvedComponent.rect.midX
                        let dy = adjustedComponent.rect.midY - resolvedComponent.rect.midY
                        
                        // Apply offset in the direction away from the overlapping component
                        let offsetDistance: CGFloat = 20
                        let offsetX = dx != 0 ? (dx > 0 ? offsetDistance : -offsetDistance) : offsetDistance
                        let offsetY = dy != 0 ? (dy > 0 ? offsetDistance : -offsetDistance) : offsetDistance
                        
                        let newRect = adjustedComponent.rect.offsetBy(dx: offsetX, dy: offsetY)
                        
                        // Ensure the component stays within canvas bounds
                        let canvasBounds = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
                        let clampedRect = clampRectToCanvas(newRect, canvasBounds: canvasBounds)
                        
                        adjustedComponent.rect = clampedRect
                        print("🔄 Moved overlapping component \(i + 1) to avoid collision")
                        break
                    }
                }
                
                attempts += 1
            }
            
            resolvedComponents.append(adjustedComponent)
        }
        
        print("🔧 Resolved overlaps: \(components.count) → \(resolvedComponents.count) components")
        return resolvedComponents
    }
    
    /// Clamps a rectangle to stay within canvas bounds while preserving its size.
    private static func clampRectToCanvas(_ rect: CGRect, canvasBounds: CGRect) -> CGRect {
        var clampedRect = rect
        
        // Adjust X position
        if clampedRect.minX < canvasBounds.minX {
            clampedRect.origin.x = canvasBounds.minX
        } else if clampedRect.maxX > canvasBounds.maxX {
            clampedRect.origin.x = canvasBounds.maxX - clampedRect.width
        }
        
        // Adjust Y position
        if clampedRect.minY < canvasBounds.minY {
            clampedRect.origin.y = canvasBounds.minY
        } else if clampedRect.maxY > canvasBounds.maxY {
            clampedRect.origin.y = canvasBounds.maxY - clampedRect.height
        }
        
        return clampedRect
    }
}

// MARK: - CGRect Distance Helper

/// Extension to compute the distance between two CGRects (edge-to-edge).
private extension CGRect {
    func distance(to other: CGRect) -> CGFloat {
        let dx = max(0, max(other.minX - self.maxX, self.minX - other.maxX))
        let dy = max(0, max(other.minY - self.maxY, self.minY - other.maxY))
        return hypot(dx, dy)
    }
} 
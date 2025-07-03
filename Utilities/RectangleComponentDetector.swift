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
        case .button:
            // Boolean properties
            properties.addBooleanProperty(BooleanProperty(name: "Has Icon", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Is Disabled", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Loading State", defaultValue: false))
            
            // Instance swap properties
            properties.addInstanceSwapProperty(InstanceSwapProperty(
                name: "Icon Type",
                availableOptions: ["arrow.right", "plus", "star", "heart", "download", "share"],
                defaultOption: "arrow.right"
            ))
            properties.addInstanceSwapProperty(InstanceSwapProperty(
                name: "Button Style",
                availableOptions: ["Primary", "Secondary", "Outline", "Ghost"],
                defaultOption: "Primary"
            ))
            
            // Enhanced text properties
            properties.addEnhancedTextProperty(EnhancedTextProperty(
                name: "Primary Text",
                content: textContent ?? "Button",
                style: .bold,
                alignment: .center
            ))
            
            // Color properties
            properties.addColorProperty(ColorProperty(name: "Primary Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .secondary))
            
        case .label:
            // Enhanced text properties
            properties.addEnhancedTextProperty(EnhancedTextProperty(
                name: "Text Content",
                content: textContent ?? "Label",
                style: .regular,
                alignment: .left
            ))
            
            // Color properties
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .primary))
            
        case .formControl:
            // Boolean properties
            properties.addBooleanProperty(BooleanProperty(name: "Is Required", defaultValue: false))
            properties.addBooleanProperty(BooleanProperty(name: "Has Error", defaultValue: false))
            
            // Enhanced text properties
            properties.addEnhancedTextProperty(EnhancedTextProperty(
                name: "Placeholder Text",
                content: "Enter text",
                style: .regular,
                alignment: .left
            ))
            
            // Color properties
            properties.addColorProperty(ColorProperty(name: "Border Color", semanticRole: .secondary))
            
        case .alert:
            // Instance swap properties
            properties.addInstanceSwapProperty(InstanceSwapProperty(
                name: "Alert Type",
                availableOptions: ["Info", "Success", "Warning", "Error"],
                defaultOption: "Info"
            ))
            
            // Boolean properties
            properties.addBooleanProperty(BooleanProperty(name: "Show Icon", defaultValue: true))
            properties.addBooleanProperty(BooleanProperty(name: "Dismissible", defaultValue: true))
            
            // Color properties
            properties.addColorProperty(ColorProperty(name: "Alert Color", semanticRole: .info))
            
        case .navbar:
            // Boolean properties
            properties.addBooleanProperty(BooleanProperty(name: "Show Logo", defaultValue: true))
            
            // Instance swap properties
            properties.addInstanceSwapProperty(InstanceSwapProperty(
                name: "Navigation Style",
                availableOptions: ["Fixed", "Sticky", "Static"],
                defaultOption: "Fixed"
            ))
            
            // Add navigation items for navbar
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
            
            // Color properties
            properties.addColorProperty(ColorProperty(name: "Background Color", semanticRole: .primary))
            properties.addColorProperty(ColorProperty(name: "Text Color", semanticRole: .secondary))
            
        default:
            // Basic text and color properties for other components
            if componentSupportsText(uiType) {
                properties.addEnhancedTextProperty(EnhancedTextProperty(
                    name: "Text Content",
                    content: textContent ?? DetectedComponent.defaultTextContent(for: type) ?? "",
                    style: .regular,
                    alignment: .left
                ))
            }
            
            properties.addColorProperty(ColorProperty(name: "Primary Color", semanticRole: .primary))
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
        return rects.filter { rect in
            // Minimum size thresholds (relative to canvas)
            let minWidth = canvasSize.width * 0.05  // At least 5% of canvas width
            let minHeight = canvasSize.height * 0.05  // At least 5% of canvas height
            let minArea = canvasSize.width * canvasSize.height * 0.003  // At least 0.3% of canvas area
            
            // Check minimum dimensions
            guard rect.width >= minWidth && rect.height >= minHeight else {
                print("  ❌ Filtered out small rect: \(rect) (too small)")
                return false
            }
            
            // Check minimum area
            guard rect.width * rect.height >= minArea else {
                print("  ❌ Filtered out small rect: \(rect) (insufficient area)")
                return false
            }
            
            // Check aspect ratio (not too extreme)
            let aspectRatio = rect.width / rect.height
            guard aspectRatio >= 0.1 && aspectRatio <= 10.0 else {
                print("  ❌ Filtered out rect with extreme aspect ratio: \(rect) (aspect: \(aspectRatio))")
                return false
            }
            
            // Check if rectangle is within canvas bounds (with some tolerance)
            let canvasBounds = CGRect(x: -10, y: -10, width: canvasSize.width + 20, height: canvasSize.height + 20)
            guard canvasBounds.contains(rect) else {
                print("  ❌ Filtered out rect outside canvas: \(rect)")
                return false
            }
            
            print("  ✅ Keeping quality rect: \(rect)")
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
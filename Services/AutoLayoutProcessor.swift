import Foundation
import CoreGraphics

/// Figma-style auto-layout processor for transforming raw component positions into beautiful, responsive layouts
/// Analyzes spatial relationships and applies consistent spacing, alignment, and grouping rules
class AutoLayoutProcessor {
    
    // MARK: - Auto Layout Configuration
    
    struct LayoutConfig {
        let isEnabled: Bool
        let containerPadding: CGFloat
        let componentGap: CGFloat
        let sectionGap: CGFloat
        let alignmentTolerance: CGFloat
        let useResponsiveGrid: Bool
        let maxContentWidth: CGFloat
        
        static let `default` = LayoutConfig(
            isEnabled: true,
            containerPadding: 32,      // Container margins
            componentGap: 16,          // Gap between related components
            sectionGap: 48,            // Gap between different sections
            alignmentTolerance: 20,    // Tolerance for considering items "aligned"
            useResponsiveGrid: true,   // Use CSS Grid for complex layouts
            maxContentWidth: 1200      // Max width for responsive design
        )
        
        static let disabled = LayoutConfig(
            isEnabled: false,
            containerPadding: 0,
            componentGap: 0,
            sectionGap: 0,
            alignmentTolerance: 0,
            useResponsiveGrid: false,
            maxContentWidth: 0
        )
    }
    
    // MARK: - Layout Analysis Results
    
    struct LayoutGroup {
        let id = UUID()
        let type: GroupType
        let components: [DetectedComponent]
        let direction: FlexDirection
        let alignment: AlignmentType
        let spacing: CGFloat
        let boundingRect: CGRect
        
        enum GroupType {
            case header           // Top section (navbar, title, etc.)
            case navigation       // Navigation elements
            case heroSection      // Main content area
            case cardGrid         // Grid of cards/items
            case formSection      // Form fields and controls
            case buttonGroup      // Related buttons
            case footer           // Bottom section
            case standalone       // Individual components
        }
        
        enum FlexDirection {
            case row              // Horizontal layout
            case column           // Vertical layout
            case grid             // CSS Grid layout
        }
        
        enum AlignmentType {
            case start            // flex-start
            case center           // center
            case end              // flex-end
            case spaceBetween     // space-between
            case spaceAround      // space-around
        }
    }
    
    // MARK: - Main Processing Function
    
    /// Processes components with auto-layout rules to create organized, responsive layouts
    static func processLayout(
        components: [DetectedComponent], 
        canvasSize: CGSize, 
        config: LayoutConfig = .default
    ) -> [LayoutGroup] {
        
        guard config.isEnabled && !components.isEmpty else {
            // Return components as standalone groups if auto-layout is disabled
            return components.map { LayoutGroup(
                type: .standalone,
                components: [$0],
                direction: .column,
                alignment: .start,
                spacing: 0,
                boundingRect: $0.rect
            )}
        }
        
        print("🎨 AutoLayout: Processing \(components.count) components with auto-layout")
        
        // Step 1: Analyze spatial relationships
        let spatialGroups = analyzeSpatialRelationships(components: components, config: config)
        
        // Step 2: Determine logical groupings and layout patterns
        let logicalGroups = determineLogicalGroups(spatialGroups: spatialGroups, canvasSize: canvasSize)
        
        // Step 3: Apply auto-layout rules and responsive behavior
        let layoutGroups = applyAutoLayoutRules(groups: logicalGroups, config: config)
        
        print("🎨 AutoLayout: Created \(layoutGroups.count) layout groups")
        for (i, group) in layoutGroups.enumerated() {
            print("  Group \(i+1): \(group.type) - \(group.direction) - \(group.components.count) components")
        }
        
        return layoutGroups
    }
    
    // MARK: - Spatial Analysis
    
    /// Analyzes spatial relationships between components to find rows, columns, and clusters
    private static func analyzeSpatialRelationships(
        components: [DetectedComponent], 
        config: LayoutConfig
    ) -> [[DetectedComponent]] {
        
        var groups: [[DetectedComponent]] = []
        var remainingComponents = components
        
        // Sort components by Y position (top to bottom)
        remainingComponents.sort { $0.rect.midY < $1.rect.midY }
        
        while !remainingComponents.isEmpty {
            let currentComponent = remainingComponents.removeFirst()
            var currentGroup = [currentComponent]
            
            // Find components that align horizontally (same row)
            let horizontalMatches = remainingComponents.filter { component in
                let yDifference = abs(component.rect.midY - currentComponent.rect.midY)
                return yDifference <= config.alignmentTolerance
            }
            
            // Add horizontal matches to current group
            for match in horizontalMatches {
                currentGroup.append(match)
                if let index = remainingComponents.firstIndex(where: { $0.id == match.id }) {
                    remainingComponents.remove(at: index)
                }
            }
            
            // Sort group by X position (left to right)
            currentGroup.sort { $0.rect.midX < $1.rect.midX }
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    /// Determines logical groupings based on component types and positions
    private static func determineLogicalGroups(
        spatialGroups: [[DetectedComponent]], 
        canvasSize: CGSize
    ) -> [LayoutGroup] {
        
        var layoutGroups: [LayoutGroup] = []
        
        for (index, group) in spatialGroups.enumerated() {
            let groupRect = calculateBoundingRect(for: group)
            let groupType = determineGroupType(components: group, position: groupRect, canvasSize: canvasSize, index: index)
            let direction = determineFlexDirection(components: group)
            let alignment = determineAlignment(components: group, direction: direction)
            
            let layoutGroup = LayoutGroup(
                type: groupType,
                components: group,
                direction: direction,
                alignment: alignment,
                spacing: calculateOptimalSpacing(components: group, direction: direction),
                boundingRect: groupRect
            )
            
            layoutGroups.append(layoutGroup)
        }
        
        return layoutGroups
    }
    
    /// Determines the appropriate group type based on component types and position
    private static func determineGroupType(
        components: [DetectedComponent], 
        position: CGRect, 
        canvasSize: CGSize,
        index: Int
    ) -> LayoutGroup.GroupType {
        
        let componentTypes = components.compactMap { 
            if case .ui(let uiType) = $0.type {
                return uiType
            }
            return nil
        }
        let yPosition = position.midY / canvasSize.height
        
        // Header detection (top 25% of canvas)
        if yPosition < 0.25 && (componentTypes.contains(.navbar) || componentTypes.contains(.tab) || index == 0) {
            return .header
        }
        
        // Navigation detection
        if componentTypes.contains(.navbar) || componentTypes.contains(.breadcrumb) || componentTypes.contains(.tab) {
            return .navigation
        }
        
        // Form section detection
        if componentTypes.contains(.formControl) || componentTypes.contains(.textarea) || componentTypes.contains(.dropdown) {
            return .formSection
        }
        
        // Button group detection
        if componentTypes.allSatisfy({ $0 == .button }) && components.count > 1 {
            return .buttonGroup
        }
        
        // Card grid detection
        if componentTypes.contains(.image) && componentTypes.contains(.label) {
            return .cardGrid
        }
        
        // Footer detection (bottom 25% of canvas)
        if yPosition > 0.75 {
            return .footer
        }
        
        // Hero section (large central area)
        if yPosition > 0.2 && yPosition < 0.7 && position.width > canvasSize.width * 0.6 {
            return .heroSection
        }
        
        return .standalone
    }
    
    /// Determines optimal flex direction based on component arrangement
    private static func determineFlexDirection(components: [DetectedComponent]) -> LayoutGroup.FlexDirection {
        guard components.count > 1 else { return .column }
        
        // Calculate spread in X and Y directions
        let xSpread = components.map { $0.rect.midX }.max()! - components.map { $0.rect.midX }.min()!
        let ySpread = components.map { $0.rect.midY }.max()! - components.map { $0.rect.midY }.min()!
        
        // If components are arranged more horizontally, use row
        if xSpread > ySpread * 1.5 {
            return .row
        }
        
        // If there are many components and they form a grid-like pattern, use grid
        if components.count > 4 && abs(xSpread - ySpread) < min(xSpread, ySpread) * 0.5 {
            return .grid
        }
        
        return .column
    }
    
    /// Determines optimal alignment based on component positions
    private static func determineAlignment(
        components: [DetectedComponent], 
        direction: LayoutGroup.FlexDirection
    ) -> LayoutGroup.AlignmentType {
        
        guard components.count > 1 else { return .start }
        
        if direction == .row {
            // Check vertical alignment for horizontal layouts
            let yPositions = components.map { $0.rect.midY }
            let yVariance = calculateVariance(values: yPositions)
            
            if yVariance < 100 { // Components are well-aligned
                return .center
            }
        } else {
            // Check horizontal alignment for vertical layouts
            let xPositions = components.map { $0.rect.midX }
            let xVariance = calculateVariance(values: xPositions)
            
            if xVariance < 100 { // Components are well-aligned
                return .center
            }
        }
        
        return .start
    }
    
    /// Calculates optimal spacing between components
    private static func calculateOptimalSpacing(
        components: [DetectedComponent], 
        direction: LayoutGroup.FlexDirection
    ) -> CGFloat {
        
        guard components.count > 1 else { return 16 }
        
        // Calculate actual spacing between components
        let sortedComponents = direction == .row 
            ? components.sorted { $0.rect.midX < $1.rect.midX }
            : components.sorted { $0.rect.midY < $1.rect.midY }
        
        var spacings: [CGFloat] = []
        for i in 1..<sortedComponents.count {
            let prev = sortedComponents[i-1]
            let current = sortedComponents[i]
            
            let spacing = direction == .row 
                ? current.rect.minX - prev.rect.maxX
                : current.rect.minY - prev.rect.maxY
            
            if spacing > 0 {
                spacings.append(spacing)
            }
        }
        
        // Use median spacing, with sensible defaults
        let medianSpacing = spacings.isEmpty ? 16 : spacings.sorted()[spacings.count / 2]
        return max(8, min(48, medianSpacing)) // Clamp between 8px and 48px
    }
    
    // MARK: - Auto Layout Rules Application
    
    /// Applies auto-layout rules and generates responsive behavior
    private static func applyAutoLayoutRules(
        groups: [LayoutGroup], 
        config: LayoutConfig
    ) -> [LayoutGroup] {
        
        return groups.map { group in
            var updatedGroup = group
            
            // Apply spacing rules based on group type
            switch group.type {
            case .header, .navigation:
                updatedGroup = LayoutGroup(
                    type: group.type,
                    components: group.components,
                    direction: .row,
                    alignment: .spaceBetween,
                    spacing: config.componentGap,
                    boundingRect: group.boundingRect
                )
                
            case .buttonGroup:
                updatedGroup = LayoutGroup(
                    type: group.type,
                    components: group.components,
                    direction: .row,
                    alignment: .center,
                    spacing: config.componentGap / 2, // Tighter spacing for buttons
                    boundingRect: group.boundingRect
                )
                
            case .formSection:
                updatedGroup = LayoutGroup(
                    type: group.type,
                    components: group.components,
                    direction: .column,
                    alignment: .start,
                    spacing: config.componentGap,
                    boundingRect: group.boundingRect
                )
                
            case .cardGrid:
                updatedGroup = LayoutGroup(
                    type: group.type,
                    components: group.components,
                    direction: .grid,
                    alignment: .start,
                    spacing: config.componentGap * 1.5, // More spacing for cards
                    boundingRect: group.boundingRect
                )
                
            default:
                break
            }
            
            return updatedGroup
        }
    }
    
    // MARK: - Utility Functions
    
    /// Calculates the bounding rectangle for a group of components
    private static func calculateBoundingRect(for components: [DetectedComponent]) -> CGRect {
        guard !components.isEmpty else { return .zero }
        
        let minX = components.map { $0.rect.minX }.min()!
        let minY = components.map { $0.rect.minY }.min()!
        let maxX = components.map { $0.rect.maxX }.max()!
        let maxY = components.map { $0.rect.maxY }.max()!
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    /// Calculates variance for alignment detection
    private static func calculateVariance(values: [CGFloat]) -> CGFloat {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / CGFloat(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / CGFloat(values.count)
    }
    
    // MARK: - CSS Generation Helpers
    
    /// Generates CSS classes for auto-layout groups
    static func generateAutoLayoutCSS(groups: [LayoutGroup], config: LayoutConfig) -> String {
        let css = """
        /* Auto-Layout CSS - Generated by SketchSite */
        .auto-layout-container {
            max-width: \(Int(config.maxContentWidth))px;
            margin: 0 auto;
            padding: \(Int(config.containerPadding))px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            gap: \(Int(config.sectionGap))px;
        }
        
        .layout-group {
            display: flex;
            align-items: center;
        }
        
        .group-header { justify-content: space-between; }
        .group-navigation { justify-content: space-between; padding: 16px 0; }
        .group-hero { justify-content: center; text-align: center; padding: 48px 0; }
        .group-button { gap: 8px; justify-content: center; }
        .group-form { flex-direction: column; align-items: stretch; gap: 16px; }
        .group-footer { justify-content: center; padding: 32px 0; margin-top: auto; }
        
        .group-card-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 24px;
            align-items: start;
        }
        
        /* Responsive Design */
        @media (max-width: 768px) {
            .auto-layout-container { padding: 16px; gap: 24px; }
            .group-navigation { flex-direction: column; gap: 12px; }
            .group-card-grid { grid-template-columns: 1fr; }
            .group-button { flex-wrap: wrap; }
        }
        
        """
        
        return css
    }
    
    /// Generates the layout structure description for AI prompt
    static func generateLayoutDescription(groups: [LayoutGroup]) -> String {
        var descriptions: [String] = []
        
        for (index, group) in groups.enumerated() {
            let componentList = group.components.map { "\($0.type.description)" }.joined(separator: ", ")
            let description = """
            Section \(index + 1) (\(group.type)): \(componentList)
            - Layout: \(group.direction) with \(group.alignment) alignment
            - Spacing: \(Int(group.spacing))px gaps
            - Components: \(group.components.count)
            """
            descriptions.append(description)
        }
        
        return descriptions.joined(separator: "\n\n")
    }
}

// MARK: - Layout Group Type Extensions

extension AutoLayoutProcessor.LayoutGroup.GroupType: CustomStringConvertible {
    var description: String {
        switch self {
        case .header: return "Header"
        case .navigation: return "Navigation" 
        case .heroSection: return "Hero Section"
        case .cardGrid: return "Card Grid"
        case .formSection: return "Form Section"
        case .buttonGroup: return "Button Group"
        case .footer: return "Footer"
        case .standalone: return "Standalone"
        }
    }
}

extension AutoLayoutProcessor.LayoutGroup.FlexDirection: CustomStringConvertible {
    var description: String {
        switch self {
        case .row: return "horizontal"
        case .column: return "vertical"
        case .grid: return "grid"
        }
    }
}

extension AutoLayoutProcessor.LayoutGroup.AlignmentType: CustomStringConvertible {
    var description: String {
        switch self {
        case .start: return "flex-start"
        case .center: return "center"
        case .end: return "flex-end"
        case .spaceBetween: return "space-between"
        case .spaceAround: return "space-around"
        }
    }
} 
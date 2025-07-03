import Foundation
import CoreGraphics

/// Enum representing common UI component types for detection and code generation.
public enum UIComponentType: String, CaseIterable {
    case alert
    case badge
    case breadcrumb
    case button
    case buttonGroup = "button group"
    case carousel
    case collapse
    case dropdown
    case form
    case formControl = "form control"
    case icon
    case image
    case label
    case listGroup = "list group"
    case mediaObject = "media object"
    case modal
    case navbar
    case navs
    case pagination
    case progressBar = "progress bar"
    case table
    case tab
    case thumbnail
    case tooltip
    case well
}

/// Utility for describing detected UI components in a human-readable format with advanced properties.
public struct LayoutDescriptor {
    /// Describes detected components in a human-readable way for prompt or debugging, including advanced properties.
    /// - Parameters:
    ///   - components: The detected UI components.
    ///   - canvasSize: The size of the canvas for relative position calculation.
    /// - Returns: A string describing each element's type, size, position, and properties.
    public static func describe(components: [DetectedComponent], canvasSize: CGSize) -> String {
        components.enumerated().map { (idx, comp) in
            let size = "\(Int(comp.rect.width))×\(Int(comp.rect.height))"
            let pos = positionDescription(for: comp.rect, canvasSize: canvasSize)
            let label = comp.label != nil ? ", label: \(comp.label!)" : ""
            let textContent = comp.textContent != nil ? ", text: \"\(comp.textContent!)\"" : ""
            let properties = describeAdvancedProperties(comp.properties)
            
            return "Element \(idx + 1) (\(comp.type)): \(size) at \(pos)\(label)\(textContent)\(properties)"
        }.joined(separator: "\n")
    }
    
    /// Describes advanced component properties for AI code generation
    private static func describeAdvancedProperties(_ properties: ComponentProperties) -> String {
        var descriptions: [String] = []
        
        // Boolean Properties
        if !properties.booleanProperties.isEmpty {
            let booleanDesc = properties.booleanProperties.map { prop in
                "\(prop.name): \(prop.currentValue ? "enabled" : "disabled")"
            }.joined(separator: ", ")
            descriptions.append("Boolean[\(booleanDesc)]")
        }
        
        // Instance Swap Properties
        if !properties.instanceSwapProperties.isEmpty {
            let swapDesc = properties.instanceSwapProperties.map { prop in
                "\(prop.name): \(prop.currentOption)"
            }.joined(separator: ", ")
            descriptions.append("InstanceSwap[\(swapDesc)]")
        }
        
        // Enhanced Text Properties
        if !properties.enhancedTextProperties.isEmpty {
            let textDesc = properties.enhancedTextProperties.map { prop in
                "\(prop.name): \"\(prop.content)\" (style: \(prop.style.displayName), align: \(prop.alignment.displayName))"
            }.joined(separator: ", ")
            descriptions.append("Text[\(textDesc)]")
        }
        
        // Color Properties
        if !properties.colorProperties.isEmpty {
            let colorDesc = properties.colorProperties.map { prop in
                "\(prop.name): \(prop.currentColor) (\(prop.semanticRole.displayName))"
            }.joined(separator: ", ")
            descriptions.append("Colors[\(colorDesc)]")
        }
        
        // Navigation Items Properties
        if !properties.navigationItemsProperties.isEmpty {
            let navDesc = properties.navigationItemsProperties.map { prop in
                let activeItems = prop.items.filter { $0.isActive }.map { $0.text }
                let allItems = prop.items.map { $0.text }
                return "\(prop.name): [\(allItems.joined(separator: ", "))] (active: \(activeItems.joined(separator: ", ")))"
            }.joined(separator: ", ")
            descriptions.append("Navigation[\(navDesc)]")
        }
        
        return descriptions.isEmpty ? "" : ", Properties: " + descriptions.joined(separator: "; ")
    }
    
    /// Generates detailed property instructions for AI code generation
    public static func generatePropertyInstructions(for components: [DetectedComponent]) -> String {
        var instructions: [String] = []
        
        for (idx, component) in components.enumerated() {
            let elementNumber = idx + 1
            var elementInstructions: [String] = []
            
            // Boolean Properties Instructions
            for boolProp in component.properties.booleanProperties {
                if boolProp.currentValue {
                    switch boolProp.name {
                    case "Has Icon":
                        elementInstructions.append("include an icon")
                    case "Is Disabled":
                        elementInstructions.append("make it disabled/non-interactive")
                    case "Loading State":
                        elementInstructions.append("show loading spinner/state")
                    case "Show Logo":
                        elementInstructions.append("include a logo")
                    case "Show Icon":
                        elementInstructions.append("display an icon")
                    case "Dismissible":
                        elementInstructions.append("add dismiss/close functionality")
                    case "Is Required":
                        elementInstructions.append("mark as required field")
                    case "Has Error":
                        elementInstructions.append("show error state")
                    default:
                        elementInstructions.append("enable \(boolProp.name.lowercased())")
                    }
                }
            }
            
            // Instance Swap Instructions
            for swapProp in component.properties.instanceSwapProperties {
                switch swapProp.name {
                case "Icon Type":
                    elementInstructions.append("use \(swapProp.currentOption) icon")
                case "Button Style":
                    elementInstructions.append("style as \(swapProp.currentOption.lowercased()) button")
                case "Alert Type":
                    elementInstructions.append("make it a \(swapProp.currentOption.lowercased()) alert")
                case "Navigation Style":
                    elementInstructions.append("use \(swapProp.currentOption.lowercased()) navigation style")
                case "Orientation":
                    elementInstructions.append("arrange in \(swapProp.currentOption.lowercased()) orientation")
                default:
                    elementInstructions.append("set \(swapProp.name.lowercased()) to \(swapProp.currentOption)")
                }
            }
            
            // Enhanced Text Instructions
            for textProp in component.properties.enhancedTextProperties {
                var textInstruction = "text content: \"\(textProp.content)\""
                if textProp.style != .regular {
                    textInstruction += " with \(textProp.style.displayName.lowercased()) style"
                }
                if textProp.alignment != .left {
                    textInstruction += " aligned \(textProp.alignment.displayName.lowercased())"
                }
                elementInstructions.append(textInstruction)
            }
            
            // Color Instructions
            for colorProp in component.properties.colorProperties {
                let colorInstruction = "\(colorProp.name.lowercased()): \(colorProp.currentColor) (\(colorProp.semanticRole.displayName) role)"
                elementInstructions.append(colorInstruction)
            }
            
            // Navigation Items Instructions
            for navProp in component.properties.navigationItemsProperties {
                let navItems = navProp.items.map { item in
                    let activeMarker = item.isActive ? " (active)" : ""
                    let iconMarker = item.icon != nil ? " with \(item.icon!) icon" : ""
                    return "\(item.text)\(activeMarker)\(iconMarker)"
                }
                elementInstructions.append("navigation items: \(navItems.joined(separator: ", "))")
            }
            
            if !elementInstructions.isEmpty {
                instructions.append("Element \(elementNumber): \(elementInstructions.joined(separator: ", "))")
            }
        }
        
        return instructions.isEmpty ? "" : "\n\n**Advanced Property Instructions:**\n" + instructions.joined(separator: "\n")
    }
    
    /// Returns a simple position description (e.g., top-left, center) for a rect on the canvas.
    private static func positionDescription(for rect: CGRect, canvasSize: CGSize) -> String {
        let x = rect.midX / canvasSize.width
        let y = rect.midY / canvasSize.height
        switch (x, y) {
        case (let x, let y) where y < 0.33:
            if x < 0.33 { return "top-left" }
            else if x > 0.66 { return "top-right" }
            else { return "top-center" }
        case (let x, let y) where y > 0.66:
            if x < 0.33 { return "bottom-left" }
            else if x > 0.66 { return "bottom-right" }
            else { return "bottom-center" }
        default:
            if x < 0.33 { return "middle-left" }
            else if x > 0.66 { return "middle-right" }
            else { return "center" }
        }
    }
}

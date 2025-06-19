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

/// Utility for describing detected UI components in a human-readable format.
public struct LayoutDescriptor {
    /// Describes detected components in a human-readable way for prompt or debugging.
    /// - Parameters:
    ///   - components: The detected UI components.
    ///   - canvasSize: The size of the canvas for relative position calculation.
    /// - Returns: A string describing each element's type, size, and position.
    public static func describe(components: [DetectedComponent], canvasSize: CGSize) -> String {
        components.enumerated().map { (idx, comp) in
            let size = "\(Int(comp.rect.width))×\(Int(comp.rect.height))"
            let pos = positionDescription(for: comp.rect, canvasSize: canvasSize)
            let label = comp.label != nil ? ", label: \(comp.label!)" : ""
            return "Element \(idx + 1) (\(comp.type)): \(size) at \(pos)\(label)"
        }.joined(separator: "\n")
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

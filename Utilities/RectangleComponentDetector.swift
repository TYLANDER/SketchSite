import Foundation
import CoreGraphics

// MARK: - DetectedComponent

/// Represents a detected UI component or group on the canvas.
public struct DetectedComponent: Identifiable, Hashable {
    public let id = UUID()                // Unique identifier for SwiftUI/ForEach
    public var rect: CGRect               // The bounding box of the component
    public var type: DetectedComponentType// The inferred type (single or group)
    public var label: String?             // Optional user annotation label
    
    // Custom initializer to maintain immutable ID
    public init(rect: CGRect, type: DetectedComponentType, label: String?) {
        self.rect = rect
        self.type = type
        self.label = label
    }
}

/// Enum for detected component types: single UI, group, or unknown.
public enum DetectedComponentType: Hashable, CustomStringConvertible {
    case ui(UIComponentType)      // A single UI component (e.g., button, image)
    case group(GroupType)         // A grouped component (e.g., nav bar, card grid)
    case unknown                  // Fallback for unclassified

    public var description: String {
        switch self {
        case .ui(let t): return t.rawValue
        case .group(let g): return g.rawValue
        case .unknown: return "unknown"
        }
    }
}

/// Enum for grouped component types (e.g., nav bar, card grid).
public enum GroupType: String, CaseIterable, Hashable {
    case navbar
    case cardGrid = "card grid"
    case buttonGroup = "button group"
    case formFieldGroup = "form field group"
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
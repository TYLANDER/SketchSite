import Foundation
import CoreGraphics

// MARK: - DetectedComponent

/// Represents a detected UI component or group on the canvas.
public struct DetectedComponent: Identifiable, Hashable {
    public let id = UUID()                // Unique identifier for SwiftUI/ForEach
    public let rect: CGRect               // The bounding box of the component
    public let type: DetectedComponentType// The inferred type (single or group)
    public let label: String?             // Optional user annotation label
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
        // 1. Group rectangles by proximity/size
        let groups = groupRectangles(rects, canvasSize: canvasSize)
        var detected: [DetectedComponent] = []
        var usedRects = Set<CGRect>()
        
        // 2. For each group, infer type
        for group in groups {
            if group.count == 1 {
                let rect = group[0]
                let type = inferType(for: rect, canvasSize: canvasSize)
                let label = annotationLabel(for: rect, annotations: annotations)
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
        // 3. Any unused rects (not grouped)
        for rect in rects where !usedRects.contains(rect) {
            let type = inferType(for: rect, canvasSize: canvasSize)
            let label = annotationLabel(for: rect, annotations: annotations)
            detected.append(DetectedComponent(rect: rect, type: .ui(type), label: label))
        }
        return detected
    }
    
    // MARK: - Grouping

    /// Groups rectangles that are close and similarly sized.
    private static func groupRectangles(_ rects: [CGRect], canvasSize: CGSize) -> [[CGRect]] {
        // Simple grouping: group rects that are horizontally or vertically aligned and close
        var groups: [[CGRect]] = []
        var used = Set<Int>()
        let threshold: CGFloat = max(canvasSize.width, canvasSize.height) * 0.05 // 5% of canvas
        for (i, rect) in rects.enumerated() {
            if used.contains(i) { continue }
            var group = [rect]
            for (j, other) in rects.enumerated() where i != j && !used.contains(j) {
                if areRectsGrouped(rect, other, threshold: threshold) {
                    group.append(other)
                    used.insert(j)
                }
            }
            used.insert(i)
            groups.append(group)
        }
        return groups
    }

    /// Returns true if two rectangles should be grouped (close and aligned).
    private static func areRectsGrouped(_ a: CGRect, _ b: CGRect, threshold: CGFloat) -> Bool {
        // Group if close horizontally or vertically
        let horiz = abs(a.minY - b.minY) < threshold && abs(a.height - b.height) < threshold
        let vert = abs(a.minX - b.minX) < threshold && abs(a.width - b.width) < threshold
        let dist = hypot(a.midX - b.midX, a.midY - b.midY)
        return (horiz || vert) && dist < threshold * 2
    }
    
    // MARK: - Type Inference

    /// Heuristically infers the UI component type for a single rectangle.
    private static func inferType(for rect: CGRect, canvasSize: CGSize) -> UIComponentType {
        let aspect = rect.width / max(rect.height, 1)
        let area = rect.width * rect.height
        let relWidth = rect.width / canvasSize.width
        let relHeight = rect.height / canvasSize.height
        // Heuristics for common UI types
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
        let avgWidth = group.map { $0.width }.reduce(0, +) / CGFloat(group.count)
        let avgHeight = group.map { $0.height }.reduce(0, +) / CGFloat(group.count)
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
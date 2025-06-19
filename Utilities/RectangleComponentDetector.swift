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
        // 3. Any unused rects (not grouped)
        for rect in rects where !usedRects.contains(rect) {
            let label = annotationLabel(for: rect, annotations: annotations)
            let type = inferType(for: rect, canvasSize: canvasSize, annotation: label)
            detected.append(DetectedComponent(rect: rect, type: .ui(type), label: label))
        }
        return detected
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
        let area = rect.width * rect.height
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
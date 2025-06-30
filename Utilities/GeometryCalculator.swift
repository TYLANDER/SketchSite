import Foundation
import CoreGraphics

/// Utility class for geometric calculations and transformations
struct GeometryCalculator {
    
    // MARK: - Rectangle Clamping
    
    /// Clamps a rectangle to stay within canvas bounds while preserving its size
    func clampRectToCanvas(_ rect: CGRect, canvasSize: CGSize) -> CGRect {
        let canvasBounds = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
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
    
    /// Creates a rectangle at a specific position (center point) with given size
    func createRectAtPosition(position: CGPoint, size: CGSize, canvasSize: CGSize) -> CGRect {
        let rect = CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return clampRectToCanvas(rect, canvasSize: canvasSize)
    }
    
    // MARK: - Distance Calculations
    
    /// Calculates the distance between two points
    func calculateDistance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return hypot(dx, dy)
    }
    
    /// Calculates the edge-to-edge distance between two rectangles
    func calculateDistance(between rect1: CGRect, and rect2: CGRect) -> CGFloat {
        let dx = max(0, max(rect2.minX - rect1.maxX, rect1.minX - rect2.maxX))
        let dy = max(0, max(rect2.minY - rect1.maxY, rect1.minY - rect2.maxY))
        return hypot(dx, dy)
    }
    
    // MARK: - Overlap Calculations
    
    /// Calculates the overlap ratio between two rectangles
    func calculateOverlapRatio(rect1: CGRect, rect2: CGRect) -> CGFloat {
        let intersection = rect1.intersection(rect2)
        let intersectionArea = intersection.width * intersection.height
        let rect1Area = rect1.width * rect1.height
        
        guard rect1Area > 0 else { return 0 }
        return intersectionArea / rect1Area
    }
    
    /// Checks if two rectangles overlap significantly
    func hasSignificantOverlap(rect1: CGRect, rect2: CGRect, threshold: CGFloat = 0.7) -> Bool {
        let overlapRatio1 = calculateOverlapRatio(rect1: rect1, rect2: rect2)
        let overlapRatio2 = calculateOverlapRatio(rect1: rect2, rect2: rect1)
        return max(overlapRatio1, overlapRatio2) > threshold
    }
    
    // MARK: - Resize Calculations
    
    /// Calculates a new rectangle based on resize handle position and translation
    func calculateNewRect(
        for position: HandlePosition,
        translation: CGSize,
        originalRect: CGRect,
        minSize: CGFloat = 20
    ) -> CGRect {
        var newRect = originalRect
        
        switch position {
        case .topLeft:
            let newWidth = max(minSize, originalRect.width - translation.width)
            let newHeight = max(minSize, originalRect.height - translation.height)
            newRect = CGRect(
                x: originalRect.maxX - newWidth,
                y: originalRect.maxY - newHeight,
                width: newWidth,
                height: newHeight
            )
        case .topRight:
            let newWidth = max(minSize, originalRect.width + translation.width)
            let newHeight = max(minSize, originalRect.height - translation.height)
            newRect = CGRect(
                x: originalRect.minX,
                y: originalRect.maxY - newHeight,
                width: newWidth,
                height: newHeight
            )
        case .bottomLeft:
            let newWidth = max(minSize, originalRect.width - translation.width)
            let newHeight = max(minSize, originalRect.height + translation.height)
            newRect = CGRect(
                x: originalRect.maxX - newWidth,
                y: originalRect.minY,
                width: newWidth,
                height: newHeight
            )
        case .bottomRight:
            let newWidth = max(minSize, originalRect.width + translation.width)
            let newHeight = max(minSize, originalRect.height + translation.height)
            newRect = CGRect(
                x: originalRect.minX,
                y: originalRect.minY,
                width: newWidth,
                height: newHeight
            )
        case .top:
            let newHeight = max(minSize, originalRect.height - translation.height)
            newRect = CGRect(
                x: originalRect.minX,
                y: originalRect.maxY - newHeight,
                width: originalRect.width,
                height: newHeight
            )
        case .bottom:
            let newHeight = max(minSize, originalRect.height + translation.height)
            newRect = CGRect(
                x: originalRect.minX,
                y: originalRect.minY,
                width: originalRect.width,
                height: newHeight
            )
        case .left:
            let newWidth = max(minSize, originalRect.width - translation.width)
            newRect = CGRect(
                x: originalRect.maxX - newWidth,
                y: originalRect.minY,
                width: newWidth,
                height: originalRect.height
            )
        case .right:
            let newWidth = max(minSize, originalRect.width + translation.width)
            newRect = CGRect(
                x: originalRect.minX,
                y: originalRect.minY,
                width: newWidth,
                height: originalRect.height
            )
        }
        
        return newRect
    }
    
    // MARK: - Handle Positioning
    
    /// Calculates the offset for a resize handle relative to the component rectangle center
    func calculateHandleOffset(
        for position: HandlePosition,
        componentSize: CGSize,
        handleSize: CGFloat
    ) -> CGSize {
        let halfWidth = componentSize.width / 2
        let halfHeight = componentSize.height / 2
        let offset = handleSize / 2
        
        switch position {
        case .topLeft:
            return CGSize(width: -halfWidth - offset, height: -halfHeight - offset)
        case .topRight:
            return CGSize(width: halfWidth + offset, height: -halfHeight - offset)
        case .bottomLeft:
            return CGSize(width: -halfWidth - offset, height: halfHeight + offset)
        case .bottomRight:
            return CGSize(width: halfWidth + offset, height: halfHeight + offset)
        case .top:
            return CGSize(width: 0, height: -halfHeight - offset)
        case .bottom:
            return CGSize(width: 0, height: halfHeight + offset)
        case .left:
            return CGSize(width: -halfWidth - offset, height: 0)
        case .right:
            return CGSize(width: halfWidth + offset, height: 0)
        }
    }
    
    // MARK: - Validation
    
    /// Checks if a rectangle is within canvas bounds
    func isRectWithinBounds(_ rect: CGRect, canvasSize: CGSize) -> Bool {
        let canvasBounds = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
        return canvasBounds.contains(rect)
    }
    
    /// Validates that a rectangle has minimum required dimensions
    func isRectValidSize(_ rect: CGRect, minSize: CGFloat = 20) -> Bool {
        return rect.width >= minSize && rect.height >= minSize
    }
    
    // MARK: - Position Descriptions
    
    /// Returns a human-readable position description for a rectangle on the canvas
    func positionDescription(for rect: CGRect, canvasSize: CGSize) -> String {
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
    
    // MARK: - Coordinate Conversions
    
    /// Converts Vision normalized coordinates to canvas coordinates
    func convertVisionToCanvas(boundingBox: CGRect, canvasSize: CGSize) -> CGRect {
        let width = boundingBox.width * canvasSize.width
        let height = boundingBox.height * canvasSize.height
        let x = boundingBox.minX * canvasSize.width
        let y = (1 - boundingBox.maxY) * canvasSize.height // Flip Y coordinate
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// Converts canvas coordinates to Vision normalized coordinates
    func convertCanvasToVision(rect: CGRect, canvasSize: CGSize) -> CGRect {
        let x = rect.minX / canvasSize.width
        let y = 1 - (rect.maxY / canvasSize.height) // Flip Y coordinate
        let width = rect.width / canvasSize.width
        let height = rect.height / canvasSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
} 
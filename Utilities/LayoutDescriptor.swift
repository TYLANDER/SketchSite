import Foundation
import CoreGraphics

struct LayoutDescriptor {
    static func describe(rects: [CGRect], canvasSize: CGSize) -> String {
        var descriptions: [String] = []

        for (index, rect) in rects.enumerated() {
            let centerX = rect.midX
            let centerY = rect.midY

            let horizontal = centerX < canvasSize.width / 3 ? "left"
                : (centerX > 2 * canvasSize.width / 3 ? "right" : "center")
            let vertical = centerY < canvasSize.height / 3 ? "top"
                : (centerY > 2 * canvasSize.height / 3 ? "bottom" : "middle")

            let label = "Element \(index + 1)"
            let desc = "\(label): \(Int(rect.width))×\(Int(rect.height)) near the \(vertical)-\(horizontal)"
            descriptions.append(desc)
        }

        return descriptions.joined(separator: "\n")
    }
}

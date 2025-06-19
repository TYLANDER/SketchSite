import PencilKit
import UIKit

/// Extension to capture a UIImage snapshot of the current PKCanvasView drawing.
extension PKCanvasView {
    /// Returns a UIImage snapshot of the current canvas contents.
    func snapshotImage() -> UIImage? {
        let bounds = self.bounds
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        return renderer.image { context in
            self.layer.render(in: context.cgContext)
        }
    }
}

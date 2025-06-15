import PencilKit
import UIKit

extension PKCanvasView {
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

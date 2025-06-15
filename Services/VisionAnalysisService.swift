import Foundation
import Vision
import UIKit

class VisionAnalysisService {
    
    func detectRectangles(in image: UIImage, completion: @escaping ([VNRectangleObservation]) -> Void) {
        guard let cgImage = image.cgImage else {
            print("❌ Failed to convert UIImage to CGImage")
            completion([])
            return
        }

        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation], error == nil else {
                print("❌ Vision error: \(String(describing: error))")
                completion([])
                return
            }
            completion(results)
        }

        // You can tweak these for better rectangle detection
        request.minimumSize = 0.1
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.minimumConfidence = 0.5
        request.quadratureTolerance = 20.0

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform Vision request: \(error)")
                completion([])
            }
        }
    }
}

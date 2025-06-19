import Foundation
import Vision
import UIKit
import VisionKit
import CoreGraphics

/// Service for analyzing images using Vision to detect rectangles, text, and infer UI layout components.
class VisionAnalysisService {
    /// Detects rectangles in a UIImage using Vision and returns VNRectangleObservation results.
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
    
    /// Detects text annotations in a UIImage using Vision and returns VNRecognizedTextObservation results.
    func detectTextAnnotations(in image: UIImage, completion: @escaping ([VNRecognizedTextObservation]) -> Void) {
        guard let cgImage = image.cgImage else {
            print("❌ Failed to convert UIImage to CGImage")
            completion([])
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let results = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("❌ Text recognition error: \(String(describing: error))")
                completion([])
                return
            }
            completion(results)
        }

        request.recognitionLanguages = ["en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform text annotation request: \(error)")
                completion([])
            }
        }
    }
    
    /// Detects rectangles and text, then infers components and returns [DetectedComponent].
    /// - Parameters:
    ///   - image: The UIImage to analyze.
    ///   - canvasSize: The size of the canvas for coordinate conversion.
    ///   - completion: Completion handler with detected components.
    func detectLayoutAndAnnotations(
        in image: UIImage,
        canvasSize: CGSize,
        completion: @escaping ([DetectedComponent]) -> Void
    ) {
        let dispatchGroup = DispatchGroup()
        var rectangles: [VNRectangleObservation] = []
        var annotations: [VNRecognizedTextObservation] = []

        dispatchGroup.enter()
        detectRectangles(in: image) {
            rectangles = $0
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        detectTextAnnotations(in: image) {
            annotations = $0
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            // Convert Vision boundingBoxes to canvas coordinates
            let rects: [CGRect] = rectangles.map { rect in
                let bb = rect.boundingBox
                let width = bb.width * canvasSize.width
                let height = bb.height * canvasSize.height
                let x = bb.minX * canvasSize.width
                let y = (1 - bb.maxY) * canvasSize.height
                return CGRect(x: x, y: y, width: width, height: height)
            }
            let annotationObjs = AnnotationProcessor.extractAnnotations(from: annotations)
            let annotationDict: [String: CGRect] = Dictionary(uniqueKeysWithValues: annotationObjs.map { ($0.text, $0.position) })
            // Convert annotation rects to canvas coordinates
            let annotationDictCanvas: [String: CGRect] = annotationDict.mapValues { bb in
                let width = bb.width * canvasSize.width
                let height = bb.height * canvasSize.height
                let x = bb.minX * canvasSize.width
                let y = (1 - bb.maxY) * canvasSize.height
                return CGRect(x: x, y: y, width: width, height: height)
            }
            let detected = RectangleComponentDetector.detectComponents(rects: rects, annotations: annotationDictCanvas, canvasSize: canvasSize)
            completion(detected)
        }
    }
}

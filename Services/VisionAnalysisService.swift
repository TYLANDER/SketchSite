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
            print("🔍 Vision detected \(results.count) raw rectangles")
            for (idx, rect) in results.enumerated() {
                print("  Raw rect \(idx + 1): \(rect.boundingBox) confidence: \(rect.confidence)")
            }
            completion(results)
        }

        // Highly tuned parameters for precise rectangle detection with minimal duplicates
        request.minimumSize = 0.1   // Larger minimum size to filter out noise and partial detections
        request.minimumAspectRatio = 0.25  // More restrictive aspect ratios
        request.maximumAspectRatio = 4.0   // Less extreme aspect ratios
        request.minimumConfidence = 0.7    // Higher confidence threshold to reduce false positives
        request.quadratureTolerance = 10.0 // Stricter tolerance for rectangle shape quality
        request.maximumObservations = 8    // Reduce maximum detections to prevent over-detection

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
            
            // Remove duplicate/overlapping rectangles before component detection
            let deduplicatedRects = self.removeDuplicateRectangles(rects, canvasSize: canvasSize)
            print("🔍 Deduplicated rectangles: \(rects.count) → \(deduplicatedRects.count)")
            
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
            let detected = RectangleComponentDetector.detectComponents(rects: deduplicatedRects, annotations: annotationDictCanvas, canvasSize: canvasSize)
            completion(detected)
        }
    }

    /// Removes duplicate and heavily overlapping rectangles that likely represent the same drawn shape.
    private func removeDuplicateRectangles(_ rects: [CGRect], canvasSize: CGSize) -> [CGRect] {
        guard rects.count > 1 else { return rects }
        
        var uniqueRects: [CGRect] = []
        let overlapThreshold: CGFloat = 0.8 // 80% overlap threshold for considering rectangles duplicates
        
        for rect in rects.sorted(by: { $0.width * $0.height > $1.width * $1.height }) { // Process larger rectangles first
            var isDuplicate = false
            
            for existingRect in uniqueRects {
                let intersection = rect.intersection(existingRect)
                let intersectionArea = intersection.width * intersection.height
                let rectArea = rect.width * rect.height
                let existingArea = existingRect.width * existingRect.height
                
                // Calculate overlap ratio for both rectangles
                let overlapRatio1 = intersectionArea / rectArea
                let overlapRatio2 = intersectionArea / existingArea
                
                // If either rectangle is mostly contained within the other, consider it a duplicate
                if overlapRatio1 > overlapThreshold || overlapRatio2 > overlapThreshold {
                    print("  🔄 Removing duplicate rect: \(rect) (overlaps \(Int(max(overlapRatio1, overlapRatio2) * 100))% with existing)")
                    isDuplicate = true
                    break
                }
                
                // Also check for near-identical rectangles (same position and size within tolerance)
                let positionTolerance: CGFloat = canvasSize.width * 0.02 // 2% of canvas width
                let sizeTolerance: CGFloat = min(canvasSize.width, canvasSize.height) * 0.05 // 5% tolerance
                
                if abs(rect.midX - existingRect.midX) < positionTolerance &&
                   abs(rect.midY - existingRect.midY) < positionTolerance &&
                   abs(rect.width - existingRect.width) < sizeTolerance &&
                   abs(rect.height - existingRect.height) < sizeTolerance {
                    print("  🔄 Removing near-identical rect: \(rect)")
                    isDuplicate = true
                    break
                }
            }
            
            if !isDuplicate {
                uniqueRects.append(rect)
                print("  ✅ Keeping unique rect: \(rect)")
            }
        }
        
        return uniqueRects
    }
}

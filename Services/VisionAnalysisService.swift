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

        // iPad-optimized parameters for better Apple Pencil detection
        // Detect device type to adjust parameters accordingly
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        if isIPad {
            // More lenient parameters for iPad Apple Pencil input
            request.minimumSize = 0.03        // Much smaller minimum size for hand-drawn rectangles
            request.minimumAspectRatio = 0.1   // Allow more extreme aspect ratios for flexible drawing
            request.maximumAspectRatio = 10.0  // Allow very wide/tall rectangles
            request.minimumConfidence = 0.4    // Lower confidence threshold for hand-drawn shapes
            request.quadratureTolerance = 20.0 // More forgiving tolerance for imperfect rectangles
            request.maximumObservations = 12   // Allow more detections for complex layouts
            print("🎨 Using iPad-optimized vision parameters for Apple Pencil input")
        } else {
            // More precise parameters for iPhone touch input
            request.minimumSize = 0.08        // Slightly relaxed from original 0.1
            request.minimumAspectRatio = 0.2  
            request.maximumAspectRatio = 5.0   
            request.minimumConfidence = 0.6    // Slightly relaxed from original 0.7
            request.quadratureTolerance = 15.0 // Slightly more forgiving
            request.maximumObservations = 10   
            print("📱 Using iPhone-optimized vision parameters for touch input")
        }

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
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            print("🎯 Vision analysis completed for \(isIPad ? "iPad" : "iPhone") - Canvas: \(Int(canvasSize.width))×\(Int(canvasSize.height))")
            print("📊 Raw vision results: \(rectangles.count) rectangles, \(annotations.count) text annotations")
            
            // Convert Vision boundingBoxes to canvas coordinates and clamp to canvas bounds
            let rects: [CGRect] = rectangles.compactMap { rect in
                let bb = rect.boundingBox
                let width = bb.width * canvasSize.width
                let height = bb.height * canvasSize.height
                let x = bb.minX * canvasSize.width
                let y = (1 - bb.maxY) * canvasSize.height
                
                let originalRect = CGRect(x: x, y: y, width: width, height: height)
                print("  🔄 Converting vision rect: \(bb) → canvas rect: \(originalRect) (confidence: \(rect.confidence))")
                
                // More lenient size checking for iPad
                let minSize: CGFloat = isIPad ? 8.0 : 10.0
                
                // Clamp rectangle to canvas bounds
                let canvasBounds = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
                let clampedRect = originalRect.intersection(canvasBounds)
                
                // Only keep rectangles that have meaningful size after clamping
                guard clampedRect.width > minSize && clampedRect.height > minSize else {
                    print("  ❌ Filtered out rect too small after clamping: \(originalRect) → \(clampedRect) (min: \(minSize))")
                    return nil
                }
                
                print("  ✅ Converted rect: \(clampedRect)")
                return clampedRect
            }
            
            print("📐 After coordinate conversion: \(rects.count) rectangles")
            for (i, rect) in rects.enumerated() {
                print("  Rect \(i+1): \(rect) (area: \(Int(rect.width * rect.height)))")
            }
            
            // Remove duplicate/overlapping rectangles before component detection
            let deduplicatedRects = self.removeDuplicateRectangles(rects, canvasSize: canvasSize)
            print("🔍 After deduplication: \(rects.count) → \(deduplicatedRects.count)")
            
            if deduplicatedRects.isEmpty {
                print("⚠️ No rectangles passed deduplication - check drawing clarity and size")
                completion([])
                return
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
            
            print("🎯 Sending \(deduplicatedRects.count) rectangles to component detector...")
            let detected = RectangleComponentDetector.detectComponents(rects: deduplicatedRects, annotations: annotationDictCanvas, canvasSize: canvasSize)
            print("🎉 Final result: \(detected.count) components detected")
            
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

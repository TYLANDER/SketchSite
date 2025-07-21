import Foundation
import Vision
import UIKit
import CoreGraphics

/// Service for recognizing professional UI/UX sketching patterns and wireframe symbols
/// Detects common sketching conventions used by designers with Apple Pencil on iPad
public class SketchPatternRecognitionService {
    
    // MARK: - Pattern Detection Results
    
    public struct SketchedPattern: Identifiable {
        public let id = UUID()
        public let type: PatternType
        public let boundingBox: CGRect
        public let confidence: Float
        public let associatedRectangle: CGRect? // The main UI element this pattern belongs to
        
        public init(type: PatternType, boundingBox: CGRect, confidence: Float, associatedRectangle: CGRect?) {
            self.type = type
            self.boundingBox = boundingBox
            self.confidence = confidence
            self.associatedRectangle = associatedRectangle
        }
        
        public enum PatternType: String, CaseIterable {
            case hamburgerMenu = "hamburger_menu"
            case imagePlaceholder = "image_placeholder"
            case formField = "form_field"
            case checkbox = "checkbox"
            case radioButton = "radio_button"
            case iconSymbol = "icon_symbol"
            case cardWithElements = "card_with_elements"
            case textLines = "text_lines"
            case dropdownArrow = "dropdown_arrow"
            case buttonIcon = "button_icon"
            case progressBar = "progress_bar"
            case tabIndicator = "tab_indicator"
            
            public var displayName: String {
                switch self {
                case .hamburgerMenu: return "Hamburger Menu"
                case .imagePlaceholder: return "Image Placeholder"
                case .formField: return "Form Field"
                case .checkbox: return "Checkbox"
                case .radioButton: return "Radio Button"
                case .iconSymbol: return "Icon"
                case .cardWithElements: return "Card with Elements"
                case .textLines: return "Text Lines"
                case .dropdownArrow: return "Dropdown Arrow"
                case .buttonIcon: return "Button Icon"
                case .progressBar: return "Progress Bar"
                case .tabIndicator: return "Tab Indicator"
                }
            }
        }
    }
    
    // MARK: - Main Detection Function
    
    /// Detects sketched UI patterns in an image
    public func detectSketchedPatterns(in image: UIImage, completion: @escaping ([SketchedPattern]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        var detectedPatterns: [SketchedPattern] = []
        let dispatchGroup = DispatchGroup()
        
        // Detect different types of patterns in parallel
        dispatchGroup.enter()
        detectLinePatterns(in: cgImage) { patterns in
            detectedPatterns.append(contentsOf: patterns)
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        detectGeometricPatterns(in: cgImage) { patterns in
            detectedPatterns.append(contentsOf: patterns)
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        detectTextualPatterns(in: cgImage) { patterns in
            detectedPatterns.append(contentsOf: patterns)
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            print("🎨 Detected \(detectedPatterns.count) sketched patterns")
            completion(detectedPatterns)
        }
    }
    
    // MARK: - Line Pattern Detection
    
    /// Detects line-based patterns like hamburger menus, form fields, and text lines
    private func detectLinePatterns(in cgImage: CGImage, completion: @escaping ([SketchedPattern]) -> Void) {
        // Use rectangle detection as a foundation for detecting line patterns
        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation], error == nil else {
                completion([])
                return
            }
            
            var patterns: [SketchedPattern] = []
            
            // Analyze rectangles for potential line-based patterns
            for rectangle in results {
                let aspectRatio = rectangle.boundingBox.width / rectangle.boundingBox.height
                let boundingBox = rectangle.boundingBox
                
                // Detect hamburger menu (very wide, short rectangles could be menu lines)
                if aspectRatio > 3.0 && boundingBox.height < 0.05 {
                    patterns.append(SketchedPattern(
                        type: .hamburgerMenu,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.8,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Detect form fields (moderate aspect ratio with internal structure hints)
                else if aspectRatio > 2.0 && aspectRatio < 6.0 && boundingBox.height > 0.03 && boundingBox.height < 0.15 {
                    patterns.append(SketchedPattern(
                        type: .formField,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.7,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Detect text lines (longer, thinner rectangles)
                else if aspectRatio > 4.0 && boundingBox.height < 0.08 {
                    patterns.append(SketchedPattern(
                        type: .textLines,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.6,
                        associatedRectangle: boundingBox
                    ))
                }
            }
            
            completion(patterns)
        }
        
        // Optimize for line detection
        request.minimumSize = 0.005
        request.minimumConfidence = 0.3
        request.quadratureTolerance = 30.0
        request.maximumObservations = 15
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    

    
    // MARK: - Geometric Pattern Detection
    
    /// Detects geometric patterns like checkboxes, radio buttons, and image placeholders
    private func detectGeometricPatterns(in cgImage: CGImage, completion: @escaping ([SketchedPattern]) -> Void) {
        let request = VNDetectRectanglesRequest { request, error in
            guard let rectangles = request.results as? [VNRectangleObservation], error == nil else {
                completion([])
                return
            }
            
            var patterns: [SketchedPattern] = []
            
            // Detect geometric patterns within and around rectangles
            patterns.append(contentsOf: self.detectImagePlaceholders(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectCheckboxes(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectCardElements(rectangles, in: cgImage))
            
            completion(patterns)
        }
        
        // Optimize for hand-drawn shapes
        request.minimumSize = 0.01
        request.minimumConfidence = 0.3
        request.quadratureTolerance = 25.0
        request.maximumObservations = 20
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    /// Detects image placeholder patterns (rectangles with X or diagonal lines)
    private func detectImagePlaceholders(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            // Extract region within rectangle and look for X or diagonal patterns
            if let regionImage = extractRegion(from: cgImage, boundingBox: rectangle.boundingBox) {
                if detectXOrDiagonalPattern(in: regionImage) {
                    patterns.append(SketchedPattern(
                        type: .imagePlaceholder,
                        boundingBox: rectangle.boundingBox,
                        confidence: rectangle.confidence,
                        associatedRectangle: rectangle.boundingBox
                    ))
                }
            }
        }
        
        return patterns
    }
    
    /// Detects checkbox patterns (small squares with checkmarks or X)
    private func detectCheckboxes(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Check if it's roughly square and small enough to be a checkbox
            if abs(aspectRatio - 1.0) < 0.3 && boundingBox.width < 0.1 && boundingBox.height < 0.1 {
                if let regionImage = extractRegion(from: cgImage, boundingBox: boundingBox) {
                    if detectCheckmarkOrXPattern(in: regionImage) {
                        patterns.append(SketchedPattern(
                            type: .checkbox,
                            boundingBox: boundingBox,
                            confidence: rectangle.confidence * 0.8,
                            associatedRectangle: boundingBox
                        ))
                    }
                }
            }
        }
        
        return patterns
    }
    
    /// Detects card patterns (rectangles with internal elements)
    private func detectCardElements(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            
            // Look for larger rectangles that could be cards
            if boundingBox.width > 0.2 && boundingBox.height > 0.15 {
                if let regionImage = extractRegion(from: cgImage, boundingBox: boundingBox) {
                    let internalElements = detectInternalElements(in: regionImage)
                    
                    if internalElements >= 2 { // Cards typically have multiple internal elements
                        patterns.append(SketchedPattern(
                            type: .cardWithElements,
                            boundingBox: boundingBox,
                            confidence: min(0.9, Float(internalElements) * 0.2 + 0.3),
                            associatedRectangle: boundingBox
                        ))
                    }
                }
            }
        }
        
        return patterns
    }
    
    // MARK: - Textual Pattern Detection
    
    /// Detects text-based patterns and annotations
    private func detectTextualPatterns(in cgImage: CGImage, completion: @escaping ([SketchedPattern]) -> Void) {
        // This could be expanded to detect specific text annotations that indicate UI elements
        // For now, we'll return empty as text detection is handled elsewhere
        completion([])
    }
    
    // MARK: - Helper Methods
    
    private func extractRegion(from cgImage: CGImage, boundingBox: CGRect) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height
        
        let rect = CGRect(
            x: boundingBox.minX * CGFloat(width),
            y: (1 - boundingBox.maxY) * CGFloat(height), // Flip Y coordinate
            width: boundingBox.width * CGFloat(width),
            height: boundingBox.height * CGFloat(height)
        )
        
        return cgImage.cropping(to: rect)
    }
    
    private func detectXOrDiagonalPattern(in cgImage: CGImage) -> Bool {
        // Simplified pattern detection for X or diagonal lines in image placeholders
        // This would analyze the image for diagonal line patterns
        // For now, return a probability based on image characteristics
        return true // Placeholder implementation
    }
    
    private func detectCheckmarkOrXPattern(in cgImage: CGImage) -> Bool {
        // Detect checkmark or X patterns within small regions
        // This would analyze the image for checkmark or X-like patterns
        return true // Placeholder implementation
    }
    
    private func detectInternalElements(in cgImage: CGImage) -> Int {
        // Count internal elements within a card region
        // This would detect things like text lines, buttons, images within the card
        return Int.random(in: 1...4) // Placeholder implementation
    }
} 


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
            // Basic UI Elements
            case button = "button"                           // Rounded rectangle with text
            case icon = "icon"                              // Simple geometric shapes
            case image = "image"                            // Rectangle with X or diagonal lines
            case label = "label"                            // Horizontal text lines
            case badge = "badge"                            // Small circle or rounded rectangle
            case thumbnail = "thumbnail"                    // Small square rectangle
            
            // Form Controls
            case formControl = "form_control"               // Rectangle with input line
            case dropdown = "dropdown"                      // Rectangle with down arrow
            case checkbox = "checkbox"                      // Square with checkmark
            case radioButton = "radio_button"               // Circle with center dot
            case textInput = "text_input"                   // Rectangle with placeholder lines
            case textarea = "textarea"                      // Large rectangle with multiple text lines
            case searchField = "search_field"               // Rectangle with magnifying glass
            case toggleSwitch = "toggle_switch"             // Oval with circle inside
            
            // Navigation Elements
            case navbar = "navbar"                          // Horizontal bar with sections
            case navs = "navs"                             // Connected navigation elements
            case breadcrumb = "breadcrumb"                 // Connected elements with arrows
            case pagination = "pagination"                 // Series of small rectangles/circles
            case tab = "tab"                              // Connected rectangles at top
            case hamburgerMenu = "hamburger_menu"          // Three horizontal lines
            
            // Layout & Container Elements
            case modal = "modal"                           // Large rectangle with title area
            case alert = "alert"                          // Rectangle with icon and text areas
            case tooltip = "tooltip"                      // Small rectangle with pointer
            case well = "well"                            // Rectangle with inset appearance
            case collapse = "collapse"                    // Rectangle with expand/collapse indicator
            case carousel = "carousel"                    // Rectangle with navigation dots
            
            // Content & Media
            case table = "table"                          // Grid pattern with lines
            case listGroup = "list_group"                 // Stacked rectangles
            case mediaObject = "media_object"             // Rectangle with smaller rectangle beside
            case progressBar = "progress_bar"             // Rectangle with filled portion
            case card = "card"                            // Rectangle with internal structure
            
            // Group Elements
            case buttonGroup = "button_group"             // Connected rectangles
            case formFieldGroup = "form_field_group"      // Grouped form elements
            case cardGrid = "card_grid"                   // Grid of card elements
            
            // Legacy patterns (maintaining backward compatibility)
            case imagePlaceholder = "image_placeholder"    // Legacy image pattern
            case formField = "form_field"                 // Legacy form pattern
            case iconSymbol = "icon_symbol"               // Legacy icon pattern
            case cardWithElements = "card_with_elements"   // Legacy card pattern
            case textLines = "text_lines"                 // Legacy text pattern
            case dropdownArrow = "dropdown_arrow"         // Legacy dropdown pattern
            case buttonIcon = "button_icon"               // Legacy button pattern
            case tabIndicator = "tab_indicator"           // Legacy tab pattern
            
            public var displayName: String {
                switch self {
                // Basic UI Elements
                case .button: return "Button"
                case .icon: return "Icon"
                case .image: return "Image"
                case .label: return "Label"
                case .badge: return "Badge"
                case .thumbnail: return "Thumbnail"
                
                // Form Controls
                case .formControl: return "Form Control"
                case .dropdown: return "Dropdown"
                case .checkbox: return "Checkbox"
                case .radioButton: return "Radio Button"
                case .textInput: return "Text Input"
                case .textarea: return "Text Area"
                case .searchField: return "Search Field"
                case .toggleSwitch: return "Toggle Switch"
                
                // Navigation Elements
                case .navbar: return "Navigation Bar"
                case .navs: return "Navigation"
                case .breadcrumb: return "Breadcrumb"
                case .pagination: return "Pagination"
                case .tab: return "Tab"
                case .hamburgerMenu: return "Hamburger Menu"
                
                // Layout & Container Elements
                case .modal: return "Modal"
                case .alert: return "Alert"
                case .tooltip: return "Tooltip"
                case .well: return "Well"
                case .collapse: return "Collapse"
                case .carousel: return "Carousel"
                
                // Content & Media
                case .table: return "Table"
                case .listGroup: return "List Group"
                case .mediaObject: return "Media Object"
                case .progressBar: return "Progress Bar"
                case .card: return "Card"
                
                // Group Elements
                case .buttonGroup: return "Button Group"
                case .formFieldGroup: return "Form Field Group"
                case .cardGrid: return "Card Grid"
                
                // Legacy patterns
                case .imagePlaceholder: return "Image Placeholder"
                case .formField: return "Form Field"
                case .iconSymbol: return "Icon"
                case .cardWithElements: return "Card with Elements"
                case .textLines: return "Text Lines"
                case .dropdownArrow: return "Dropdown Arrow"
                case .buttonIcon: return "Button Icon"
                case .tabIndicator: return "Tab Indicator"
                }
            }
        }
    }
    
    // MARK: - Main Detection Function
    
    /// OPTIMIZED: Analyzes existing rectangle detection results for patterns (much faster)
    public func analyzeExistingRectangles(_ rectangles: [VNRectangleObservation], completion: @escaping ([SketchedPattern]) -> Void) {
        var patterns: [SketchedPattern] = []
        
        // Analyze existing rectangles for component-specific patterns
        for rectangle in rectangles {
            let aspectRatio = rectangle.boundingBox.width / rectangle.boundingBox.height
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            
            // BASIC UI ELEMENTS - Fast pattern recognition based on geometry
            
            // Button detection (rounded rectangle, moderate aspect ratio)
            if aspectRatio > 1.5 && aspectRatio < 4.0 && area > 0.01 && area < 0.15 {
                patterns.append(SketchedPattern(
                    type: .button,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.85,
                    associatedRectangle: boundingBox
                ))
            }
            
            // Text Input detection (wide rectangle)
            else if aspectRatio > 2.5 && aspectRatio < 8.0 && boundingBox.height > 0.03 && boundingBox.height < 0.12 {
                patterns.append(SketchedPattern(
                    type: .textInput,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.8,
                    associatedRectangle: boundingBox
                ))
            }
            
            // Text Area detection (larger, more square for multi-line text)
            else if aspectRatio > 1.2 && aspectRatio < 4.0 && area > 0.05 && boundingBox.height > 0.08 {
                patterns.append(SketchedPattern(
                    type: .textarea,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.8,
                    associatedRectangle: boundingBox
                ))
            }
            
            // Image placeholder detection (square or slightly rectangular)
            else if aspectRatio > 0.8 && aspectRatio < 1.8 && area > 0.02 {
                patterns.append(SketchedPattern(
                    type: .image,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.75,
                    associatedRectangle: boundingBox
                ))
            }
            
            // Icon detection (small, roughly square)
            else if area < 0.02 && aspectRatio > 0.6 && aspectRatio < 1.4 {
                patterns.append(SketchedPattern(
                    type: .icon,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.7,
                    associatedRectangle: boundingBox
                ))
            }
            
            // Card detection (larger rectangular areas)
            else if area > 0.1 && aspectRatio > 0.6 && aspectRatio < 2.0 {
                patterns.append(SketchedPattern(
                    type: .card,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.7,
                    associatedRectangle: boundingBox
                ))
            }
            
            // Modal detection (very large area, likely centered)
            else if area > 0.2 && aspectRatio > 0.5 && aspectRatio < 1.5 {
                patterns.append(SketchedPattern(
                    type: .modal,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.8,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        print("⚡️ Fast pattern analysis: \(patterns.count) patterns from \(rectangles.count) rectangles")
        DispatchQueue.main.async {
            completion(patterns)
        }
    }

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
    
    /// Detects comprehensive UI component patterns based on professional sketching conventions
    private func detectLinePatterns(in cgImage: CGImage, completion: @escaping ([SketchedPattern]) -> Void) {
        // Use rectangle detection as a foundation for detecting component patterns
        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation], error == nil else {
                completion([])
                return
            }
            
            var patterns: [SketchedPattern] = []
            
            // Analyze rectangles for component-specific patterns
            for rectangle in results {
                let aspectRatio = rectangle.boundingBox.width / rectangle.boundingBox.height
                let boundingBox = rectangle.boundingBox
                let area = boundingBox.width * boundingBox.height
                
                // BASIC UI ELEMENTS
                
                // Button detection (rounded rectangle, moderate aspect ratio)
                if aspectRatio > 1.5 && aspectRatio < 4.0 && area > 0.01 && area < 0.15 {
                    patterns.append(SketchedPattern(
                        type: .button,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.85,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Badge detection (small, often circular/square)
                else if area < 0.01 && aspectRatio > 0.5 && aspectRatio < 2.0 {
                    patterns.append(SketchedPattern(
                        type: .badge,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.8,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Thumbnail detection (small square)
                else if area < 0.05 && aspectRatio > 0.8 && aspectRatio < 1.2 {
                    patterns.append(SketchedPattern(
                        type: .thumbnail,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.75,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // FORM CONTROLS
                
                // Text Input detection (wide rectangle with input characteristics)
                else if aspectRatio > 2.5 && aspectRatio < 8.0 && boundingBox.height > 0.03 && boundingBox.height < 0.12 {
                    patterns.append(SketchedPattern(
                        type: .textInput,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.8,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Text Area detection (larger rectangle for multi-line text input)
                else if aspectRatio > 1.2 && aspectRatio < 4.0 && boundingBox.height > 0.12 && boundingBox.height < 0.4 && area > 0.05 {
                    patterns.append(SketchedPattern(
                        type: .textarea,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.85,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Dropdown detection (rectangular with potential arrow space)
                else if aspectRatio > 2.0 && aspectRatio < 5.0 && boundingBox.height > 0.04 && boundingBox.height < 0.1 {
                    patterns.append(SketchedPattern(
                        type: .dropdown,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.75,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Checkbox detection (small square)
                else if area < 0.008 && aspectRatio > 0.7 && aspectRatio < 1.3 {
                    patterns.append(SketchedPattern(
                        type: .checkbox,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.9,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // NAVIGATION ELEMENTS
                
                // Navigation bar detection (wide, at top/bottom)
                else if aspectRatio > 4.0 && (boundingBox.minY < 0.15 || boundingBox.maxY > 0.85) && boundingBox.height < 0.15 {
                    patterns.append(SketchedPattern(
                        type: .navbar,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.85,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Tab detection (connected rectangles, typically at top)
                else if aspectRatio > 1.0 && aspectRatio < 3.0 && boundingBox.minY < 0.3 && boundingBox.height < 0.1 {
                    patterns.append(SketchedPattern(
                        type: .tab,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.8,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Hamburger menu detection (very wide, short lines)
                else if aspectRatio > 3.0 && boundingBox.height < 0.05 {
                    patterns.append(SketchedPattern(
                        type: .hamburgerMenu,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.85,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // LAYOUT & CONTAINER ELEMENTS
                
                // Modal detection (large, centered rectangle)
                else if area > 0.2 && aspectRatio > 0.6 && aspectRatio < 2.0 {
                    patterns.append(SketchedPattern(
                        type: .modal,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.8,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Alert detection (medium rectangle, often with internal structure)
                else if area > 0.05 && area < 0.3 && aspectRatio > 1.5 && aspectRatio < 4.0 {
                    patterns.append(SketchedPattern(
                        type: .alert,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.75,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Card detection (medium rectangle with good proportions)
                else if area > 0.02 && area < 0.25 && aspectRatio > 0.8 && aspectRatio < 2.5 {
                    patterns.append(SketchedPattern(
                        type: .card,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.8,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // CONTENT & MEDIA
                
                // Progress bar detection (wide, thin rectangle)
                else if aspectRatio > 5.0 && boundingBox.height < 0.06 {
                    patterns.append(SketchedPattern(
                        type: .progressBar,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.8,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // Label/text lines detection (longer, thinner rectangles)
                else if aspectRatio > 4.0 && boundingBox.height < 0.08 {
                    patterns.append(SketchedPattern(
                        type: .label,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.7,
                        associatedRectangle: boundingBox
                    ))
                }
                
                // List group item detection (stacked medium rectangles)
                else if aspectRatio > 2.0 && aspectRatio < 6.0 && boundingBox.height > 0.06 && boundingBox.height < 0.15 {
                    patterns.append(SketchedPattern(
                        type: .listGroup,
                        boundingBox: boundingBox,
                        confidence: rectangle.confidence * 0.75,
                        associatedRectangle: boundingBox
                    ))
                }
            }
            
            completion(patterns)
        }
        
        // Optimize for comprehensive component detection
        request.minimumSize = 0.003  // Smaller minimum for detecting badges, checkboxes
        request.minimumConfidence = 0.25  // Lower confidence threshold for sketchy drawings
        request.quadratureTolerance = 40.0  // Higher tolerance for hand-drawn shapes
        request.maximumObservations = 25  // More observations for complex layouts
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    

    
    // MARK: - Geometric Pattern Detection
    
    /// Detects comprehensive geometric patterns for all UI component types
    private func detectGeometricPatterns(in cgImage: CGImage, completion: @escaping ([SketchedPattern]) -> Void) {
        let request = VNDetectRectanglesRequest { request, error in
            guard let rectangles = request.results as? [VNRectangleObservation], error == nil else {
                completion([])
                return
            }
            
            var patterns: [SketchedPattern] = []
            
            // BASIC UI ELEMENTS
            patterns.append(contentsOf: self.detectImagePlaceholders(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectIconShapes(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectBadges(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectThumbnails(rectangles, in: cgImage))
            
            // FORM CONTROLS
            patterns.append(contentsOf: self.detectCheckboxes(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectRadioButtons(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectToggleSwitches(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectDropdownArrows(rectangles, in: cgImage))
            
            // LAYOUT & CONTAINER ELEMENTS
            patterns.append(contentsOf: self.detectCardElements(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectModalElements(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectTooltipPointers(rectangles, in: cgImage))
            
            // CONTENT & MEDIA
            patterns.append(contentsOf: self.detectTableGrids(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectProgressElements(rectangles, in: cgImage))
            patterns.append(contentsOf: self.detectCarouselDots(rectangles, in: cgImage))
            
            completion(patterns)
        }
        
        // Enhanced settings for comprehensive pattern detection
        request.minimumSize = 0.002  // Smaller minimum for tiny elements
        request.minimumConfidence = 0.2  // Lower confidence for hand-drawn shapes
        request.quadratureTolerance = 35.0  // Higher tolerance for sketchy shapes
        request.maximumObservations = 30  // More observations for complex layouts
        
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
                        type: .image,
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
                            type: .card,
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
    
    // MARK: - Additional Pattern Detection Methods
    
    /// Detects icon-like geometric shapes (circles, triangles, simple symbols)
    private func detectIconShapes(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Small, roughly square shapes that could be icons
            if area < 0.02 && aspectRatio > 0.6 && aspectRatio < 1.4 {
                patterns.append(SketchedPattern(
                    type: .icon,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.6,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects badge patterns (small circular or rounded elements)
    private func detectBadges(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Very small, circular-ish shapes
            if area < 0.008 && aspectRatio > 0.7 && aspectRatio < 1.3 {
                patterns.append(SketchedPattern(
                    type: .badge,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.7,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects thumbnail patterns (small square images)
    private func detectThumbnails(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Small square shapes, larger than badges but smaller than full images
            if area > 0.008 && area < 0.04 && aspectRatio > 0.8 && aspectRatio < 1.2 {
                patterns.append(SketchedPattern(
                    type: .thumbnail,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.75,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects radio button patterns (small circles)
    private func detectRadioButtons(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Very small, circular shapes (radio buttons are typically circular)
            if area < 0.005 && aspectRatio > 0.85 && aspectRatio < 1.15 {
                patterns.append(SketchedPattern(
                    type: .radioButton,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.8,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects toggle switch patterns (oval shapes)
    private func detectToggleSwitches(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Small oval shapes (wider than tall)
            if area < 0.015 && aspectRatio > 1.5 && aspectRatio < 3.0 {
                patterns.append(SketchedPattern(
                    type: .toggleSwitch,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.7,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects dropdown arrow patterns
    private func detectDropdownArrows(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Small triangular or arrow-like shapes at the end of rectangles
            if area < 0.01 && aspectRatio > 0.5 && aspectRatio < 2.0 {
                // Check if there's a larger rectangle nearby (dropdown container)
                for otherRect in rectangles {
                    let otherBox = otherRect.boundingBox
                    let distance = sqrt(pow(boundingBox.midX - otherBox.midX, 2) + pow(boundingBox.midY - otherBox.midY, 2))
                    
                    if distance < 0.1 && otherBox.width > boundingBox.width * 2 {
                        patterns.append(SketchedPattern(
                            type: .dropdown,
                            boundingBox: otherBox,
                            confidence: rectangle.confidence * 0.6,
                            associatedRectangle: otherBox
                        ))
                        break
                    }
                }
            }
        }
        
        return patterns
    }
    
    /// Detects modal-specific elements (title bars, close buttons)
    private func detectModalElements(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            
            // Large rectangles that could be modals
            if area > 0.15 && area < 0.8 {
                patterns.append(SketchedPattern(
                    type: .modal,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.6,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects tooltip pointer elements
    private func detectTooltipPointers(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let area = boundingBox.width * boundingBox.height
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Small rectangular shapes that could be tooltips
            if area > 0.01 && area < 0.08 && aspectRatio > 1.5 && aspectRatio < 4.0 {
                patterns.append(SketchedPattern(
                    type: .tooltip,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.5,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects table grid patterns
    private func detectTableGrids(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        // Look for groups of aligned rectangles that could form a table
        let sortedRects = rectangles.sorted { $0.boundingBox.minY < $1.boundingBox.minY }
        
        for i in 0..<sortedRects.count - 2 {
            let rect1 = sortedRects[i]
            let rect2 = sortedRects[i + 1]
            let rect3 = sortedRects[i + 2]
            
            // Check if three rectangles are aligned and similar in size (table rows)
            let yDiff1 = abs(rect2.boundingBox.minY - rect1.boundingBox.maxY)
            let yDiff2 = abs(rect3.boundingBox.minY - rect2.boundingBox.maxY)
            
            if yDiff1 < 0.05 && yDiff2 < 0.05 && 
               abs(rect1.boundingBox.width - rect2.boundingBox.width) < 0.1 &&
               abs(rect2.boundingBox.width - rect3.boundingBox.width) < 0.1 {
                
                let combinedBox = CGRect(
                    x: min(rect1.boundingBox.minX, rect2.boundingBox.minX, rect3.boundingBox.minX),
                    y: rect1.boundingBox.minY,
                    width: max(rect1.boundingBox.maxX, rect2.boundingBox.maxX, rect3.boundingBox.maxX) - min(rect1.boundingBox.minX, rect2.boundingBox.minX, rect3.boundingBox.minX),
                    height: rect3.boundingBox.maxY - rect1.boundingBox.minY
                )
                
                patterns.append(SketchedPattern(
                    type: .table,
                    boundingBox: combinedBox,
                    confidence: 0.7,
                    associatedRectangle: combinedBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects progress bar elements
    private func detectProgressElements(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        for rectangle in rectangles {
            let boundingBox = rectangle.boundingBox
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Very wide, thin rectangles could be progress bars
            if aspectRatio > 6.0 && boundingBox.height < 0.05 {
                patterns.append(SketchedPattern(
                    type: .progressBar,
                    boundingBox: boundingBox,
                    confidence: rectangle.confidence * 0.8,
                    associatedRectangle: boundingBox
                ))
            }
        }
        
        return patterns
    }
    
    /// Detects carousel dot indicators
    private func detectCarouselDots(_ rectangles: [VNRectangleObservation], in cgImage: CGImage) -> [SketchedPattern] {
        var patterns: [SketchedPattern] = []
        
        // Look for series of small, aligned rectangles that could be carousel dots
        let smallRects = rectangles.filter { 
            let area = $0.boundingBox.width * $0.boundingBox.height
            return area < 0.01 
        }
        
        // If we find 3+ small aligned rectangles, it might be carousel dots
        if smallRects.count >= 3 {
            let combinedBox = smallRects.reduce(smallRects[0].boundingBox) { box, rect in
                box.union(rect.boundingBox)
            }
            
            patterns.append(SketchedPattern(
                type: .carousel,
                boundingBox: combinedBox,
                confidence: 0.6,
                associatedRectangle: combinedBox
            ))
        }
        
        return patterns
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

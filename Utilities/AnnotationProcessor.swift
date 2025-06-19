//
//  AnnotationProcessor.swift
//  SketchSite
//
//  Created by Tyler Schmidt on 6/17/25.
//

import Foundation
import Vision

/// Represents a user annotation detected from text on the canvas.
struct Annotation {
    let text: String
    let position: CGRect
}

/// Utility for extracting and injecting user annotations from Vision text observations.
class AnnotationProcessor {
    /// Extracts annotations from Vision text observations.
    /// - Parameter textObservations: Array of VNRecognizedTextObservation.
    /// - Returns: Array of Annotation structs with text and position.
    static func extractAnnotations(from textObservations: [VNRecognizedTextObservation]) -> [Annotation] {
        var annotations: [Annotation] = []

        for observation in textObservations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let annotation = Annotation(text: text, position: observation.boundingBox)
            annotations.append(annotation)
        }

        return annotations
    }

    /// Injects annotation descriptions into a prompt string for GPT.
    /// - Parameters:
    ///   - annotations: Array of Annotation.
    ///   - prompt: The prompt string to append to (inout).
    static func injectAnnotationsIntoPrompt(_ annotations: [Annotation], prompt: inout String) {
        guard !annotations.isEmpty else { return }

        let annotationDescriptions = annotations.map { annotation in
            return "- \"\(annotation.text)\" at position \(annotation.position)"
        }.joined(separator: "\n")

        let formatted = """
        
        --- User Sketch Annotations ---
        \(annotationDescriptions)
        """
        prompt.append(formatted)
    }
} 
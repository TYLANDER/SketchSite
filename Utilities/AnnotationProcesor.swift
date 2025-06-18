//
//  AnnotationProcesor.swift
//  SketchSite
//
//  Created by Tyler Schmidt on 6/17/25.
//


import Foundation
import Vision

struct Annotation {
    let text: String
    let position: CGRect
}

class AnnotationProcessor {
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

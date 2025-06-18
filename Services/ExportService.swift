// File: Utilities/ExportService.swift
import Foundation
import UniformTypeIdentifiers
import UIKit

class ExportService {
    static let shared = ExportService()
    private init() {}

    func export(code: String, filename: String = "GeneratedCode.html") -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        // Determine file extension
        let fileExtension = fileURL.pathExtension.lowercased()
        let formattedCode: String

        switch fileExtension {
        case "html":
            formattedCode = """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <title>Exported HTML</title>
            </head>
            <body>
            <pre><code>\(code)</code></pre>
            </body>
            </html>
            """
        case "css":
            formattedCode = "/* Exported CSS */\n\n\(code)"
        case "js":
            formattedCode = "// Exported JavaScript\n\n\(code)"
        case "json":
            formattedCode = "// Exported JSON\n\n\(code)"
        case "xml":
            formattedCode = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\(code)"
        case "txt":
            fallthrough
        default:
            formattedCode = code
        }

        do {
            try formattedCode.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Failed to write file: \(error.localizedDescription)")
            return nil
        }
    }

    func share(fileURL: URL, from controller: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList, .openInIBooks]
        controller.present(activityVC, animated: true, completion: nil)
    }
}

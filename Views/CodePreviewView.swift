import SwiftUI
import UniformTypeIdentifiers
import UIKit
import Foundation

extension AttributedString {
    init(highlightedHTML code: String) throws {
        var result = AttributedString(code)
        let patterns: [(String, Color)] = [
            ("&lt;[^&]+&gt;", .purple), // HTML tags
            ("\\b[a-z-]+(?=\\s*:)", .blue), // CSS property names
            ("#[0-9a-fA-F]{3,6}", .orange), // hex colors
            ("\\b\\d+(px|em|%)", .green) // pixel/em/% values
        ]
        for (pattern, color) in patterns {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsRange = NSRange(code.startIndex..., in: code)
            for match in regex.matches(in: code, options: [], range: nsRange) {
                if let range = Range(match.range, in: code),
                   let attributedRange = Range(range, in: result) {
                    result[attributedRange].foregroundColor = color
                }
            }
        }
        self = result
    }
}

struct CodePreviewView: View {
    var code: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let title = "Exported Code"
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 2)

                    ForEach(splitCodeBlocks(code), id: \.self) { segment in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(detectFileType(from: segment))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)

                                Spacer()

                                Button(action: {
                                    copyToClipboard(segment)
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                            .padding(.bottom, 1)

                            Group {
                                if let attributedString = try? AttributedString(highlightedHTML: segment) {
                                    Text(attributedString)
                                        .font(.system(.footnote, design: .monospaced))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                } else {
                                    Text(segment)
                                        .font(.system(.footnote, design: .monospaced))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                }
                            }
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        .padding(.bottom, 12)
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Export") {
                        _ = ExportService.shared.export(code: code)
                    }
                    Button(action: {
                        shareCodeViaAirDrop(code, title: title)
                    }) {
                        Label("AirDrop", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.setValue(text, forPasteboardType: UTType.plainText.identifier)
    }

    private func splitCodeBlocks(_ code: String) -> [String] {
        return code.components(separatedBy: "```").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func detectFileType(from code: String) -> String {
        if code.contains("<html") || code.contains("<!DOCTYPE html") {
            return "HTML"
        } else if code.contains("{") && code.contains(":") {
            return "CSS"
        } else {
            return "Code"
        }
    }
    
    private func shareCodeViaAirDrop(_ text: String, title: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(title).txt")
        do {
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
            }
        } catch {
            print("❌ Failed to write temp file for AirDrop: \(error)")
        }
    }
}

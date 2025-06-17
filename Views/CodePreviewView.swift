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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                                        .font(.system(.body, design: .monospaced))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                } else {
                                    Text(segment)
                                        .font(.system(.body, design: .monospaced))
                                        .padding()
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
                        .padding(.bottom, 16)
                    }
                }
                .padding()
            }
            .navigationTitle("Generated Code")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
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
}

import SwiftUI
import WebKit
import UIKit

struct BrowserPreviewView: UIViewRepresentable {
    let html: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        // Check if we're on iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // On iPad, immediately open in Safari and dismiss the sheet
            DispatchQueue.main.async {
                openInSafari()
                dismiss()
            }
            
            // Show a temporary message while opening Safari
            let label = UILabel()
            label.text = "Opening in Safari..."
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            label.textColor = .systemBlue
            label.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            
            return containerView
        } else {
            // On iPhone, use the in-app web view
            let webView = WKWebView()
            webView.loadHTMLString(html, baseURL: nil)
            return webView
        }
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Only update if it's a WKWebView (iPhone)
        if let webView = uiView as? WKWebView {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    private func openInSafari() {
        // Create a temporary HTML file
        let fileName = "sketchsite_preview_\(UUID().uuidString).html"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // Write HTML to temporary file
            try html.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Open in Safari
            if UIApplication.shared.canOpenURL(tempURL) {
                UIApplication.shared.open(tempURL, options: [:]) { success in
                    if success {
                        print("✅ Successfully opened preview in Safari")
                        
                        // Clean up the temporary file after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            try? FileManager.default.removeItem(at: tempURL)
                        }
                    } else {
                        print("❌ Failed to open preview in Safari")
                    }
                }
            }
        } catch {
            print("❌ Error creating temporary HTML file: \(error)")
            
            // Fallback: Try to open a data URL in Safari (less reliable but worth trying)
            if let encodedHTML = html.data(using: .utf8)?.base64EncodedString() {
                let dataURL = "data:text/html;base64,\(encodedHTML)"
                if let url = URL(string: dataURL) {
                    UIApplication.shared.open(url, options: [:])
                }
            }
        }
    }
}

// MARK: - Safari Preview Helper

/// Helper for opening HTML content directly in Safari on iPad
struct SafariPreviewHelper {
    
    /// Opens HTML content in Safari (primarily for iPad use)
    static func openInSafari(_ html: String) {
        let fileName = "sketchsite_preview_\(UUID().uuidString).html"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try html.write(to: tempURL, atomically: true, encoding: .utf8)
            
            UIApplication.shared.open(tempURL, options: [:]) { success in
                if success {
                    print("✅ Successfully opened preview in Safari")
                    
                    // Clean up after 10 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                } else {
                    print("❌ Failed to open preview in Safari")
                }
            }
        } catch {
            print("❌ Error creating temporary HTML file: \(error)")
        }
    }
} 
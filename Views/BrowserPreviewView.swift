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
    
    /// Opens HTML content in Safari using multiple fallback methods
    static func openInSafari(_ html: String) {
        print("🚀 Attempting to open HTML in Safari...")
        print("📄 HTML content length: \(html.count) characters")
        
        // Method 1: Try data URL approach (most reliable)
        if let encodedHTML = html.data(using: .utf8)?.base64EncodedString() {
            let dataURL = "data:text/html;base64,\(encodedHTML)"
            if let url = URL(string: dataURL) {
                print("🔗 Using data URL approach")
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        print("✅ Successfully opened preview in Safari via data URL")
                    } else {
                        print("❌ Data URL method failed, trying Documents directory...")
                        // Fallback to Documents directory method
                        SafariPreviewHelper.openInSafariViaDocuments(html)
                    }
                }
                return
            }
        }
        
        // Method 2: Fallback to Documents directory
        print("📁 Using Documents directory method")
        openInSafariViaDocuments(html)
    }
    
    /// Fallback method using Documents directory
    private static func openInSafariViaDocuments(_ html: String) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not access Documents directory")
            showSafariError()
            return
        }
        
        let fileName = "SketchSite_Preview_\(Date().timeIntervalSince1970).html"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            print("📝 Writing HTML to Documents: \(fileURL.path)")
            try html.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Verify file was created
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("✅ HTML file created successfully")
                
                UIApplication.shared.open(fileURL, options: [:]) { success in
                    if success {
                        print("✅ Successfully opened preview in Safari via Documents")
                        
                        // Clean up after 30 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            try? FileManager.default.removeItem(at: fileURL)
                            print("🧹 Cleaned up temporary HTML file")
                        }
                    } else {
                        print("❌ Failed to open file from Documents directory")
                        showSafariError()
                    }
                }
            } else {
                print("❌ File was not created successfully")
                showSafariError()
            }
        } catch {
            print("❌ Error creating HTML file in Documents: \(error)")
            showSafariError()
        }
    }
    
    /// Show user-friendly error message
    private static func showSafariError() {
        DispatchQueue.main.async {
            // Create a simple alert or notification
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                let alert = UIAlertController(
                    title: "Safari Preview Error",
                    message: "Unable to open preview in Safari. Please try the in-app preview instead or check your device settings.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                
                if let rootViewController = window.rootViewController {
                    rootViewController.present(alert, animated: true)
                }
            }
        }
    }
} 
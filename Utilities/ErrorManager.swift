import Foundation
import SwiftUI

// MARK: - App Error Types

/// Comprehensive error types for the SketchSite application
enum AppError: LocalizedError, Equatable {
    case visionAnalysisFailed(String)
    case codeGenerationFailed(String)
    case invalidComponentBounds
    case networkError(String)
    case fileOperationFailed(String)
    case canvasOperationFailed(String)
    case componentManipulationFailed(String)
    case validationError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .visionAnalysisFailed(let message):
            return "Vision Analysis Failed: \(message)"
        case .codeGenerationFailed(let message):
            return "Code Generation Failed: \(message)"
        case .invalidComponentBounds:
            return "Invalid component bounds - component is outside canvas area"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .fileOperationFailed(let message):
            return "File Operation Failed: \(message)"
        case .canvasOperationFailed(let message):
            return "Canvas Operation Failed: \(message)"
        case .componentManipulationFailed(let message):
            return "Component Manipulation Failed: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .visionAnalysisFailed:
            return "Try drawing clearer shapes or check if the image is valid"
        case .codeGenerationFailed:
            return "Check your internet connection and API key configuration"
        case .invalidComponentBounds:
            return "Move the component within the canvas boundaries"
        case .networkError:
            return "Check your internet connection and try again"
        case .fileOperationFailed:
            return "Check file permissions and available storage space"
        case .canvasOperationFailed:
            return "Try clearing the canvas and starting over"
        case .componentManipulationFailed:
            return "Try deselecting and reselecting the component"
        case .validationError:
            return "Check the input values and try again"
        case .unknownError:
            return "Please try again or restart the application"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .visionAnalysisFailed, .codeGenerationFailed, .networkError:
            return .high
        case .invalidComponentBounds, .componentManipulationFailed, .validationError:
            return .medium
        case .fileOperationFailed, .canvasOperationFailed:
            return .medium
        case .unknownError:
            return .high
        }
    }
}

/// Error severity levels for prioritizing error handling
enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
}

// MARK: - Error Manager

/// Centralized error management and user notification system
class ErrorManager: ObservableObject {
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    @Published var errorHistory: [ErrorLogEntry] = []
    
    private let maxErrorHistorySize = 50
    
    // MARK: - Error Handling
    
    func handleError(_ error: AppError) {
        print("🚨 ErrorManager: \(error.errorDescription ?? "Unknown error")")
        
        // Log the error
        logError(error)
        
        // Show user notification based on severity
        switch error.severity {
        case .low:
            // Log only, no user notification
            break
        case .medium, .high, .critical:
            currentError = error
            showErrorAlert = true
        }
    }
    
    func handleError(_ error: Error, context: String = "") {
        let appError: AppError
        
        if let urlError = error as? URLError {
            appError = .networkError(urlError.localizedDescription)
        } else if error.localizedDescription.lowercased().contains("vision") {
            appError = .visionAnalysisFailed(error.localizedDescription)
        } else if error.localizedDescription.lowercased().contains("network") {
            appError = .networkError(error.localizedDescription)
        } else {
            let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
            appError = .unknownError(message)
        }
        
        handleError(appError)
    }
    
    // MARK: - Specific Error Handlers
    
    func handleVisionError(_ error: Error) {
        let appError = AppError.visionAnalysisFailed(error.localizedDescription)
        handleError(appError)
    }
    
    func handleNetworkError(_ error: Error) {
        let appError = AppError.networkError(error.localizedDescription)
        handleError(appError)
    }
    
    func handleValidationError(_ message: String) {
        let appError = AppError.validationError(message)
        handleError(appError)
    }
    
    func handleComponentError(_ message: String) {
        let appError = AppError.componentManipulationFailed(message)
        handleError(appError)
    }
    
    func handleCanvasError(_ message: String) {
        let appError = AppError.canvasOperationFailed(message)
        handleError(appError)
    }
    
    // MARK: - Error Logging
    
    private func logError(_ error: AppError) {
        let entry = ErrorLogEntry(
            error: error,
            timestamp: Date(),
            context: getCurrentContext()
        )
        
        errorHistory.append(entry)
        
        // Maintain history size limit
        if errorHistory.count > maxErrorHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxErrorHistorySize)
        }
    }
    
    private func getCurrentContext() -> String {
        // In a real app, this could include current view, user actions, etc.
        return "SketchSite App Context"
    }
    
    // MARK: - Error Dismissal
    
    func dismissCurrentError() {
        currentError = nil
        showErrorAlert = false
    }
    
    // MARK: - Error History Management
    
    func clearErrorHistory() {
        errorHistory.removeAll()
        print("🗑️ ErrorManager: Cleared error history")
    }
    
    func getRecentErrors(count: Int = 10) -> [ErrorLogEntry] {
        return Array(errorHistory.suffix(count))
    }
    
    // MARK: - Error Statistics
    
    var errorCount: Int {
        errorHistory.count
    }
    
    var highSeverityErrorCount: Int {
        errorHistory.filter { $0.error.severity == .high || $0.error.severity == .critical }.count
    }
    
    func getErrorCount(for severity: ErrorSeverity) -> Int {
        errorHistory.filter { $0.error.severity == severity }.count
    }
    
    // MARK: - Debug Information
    
    func printErrorSummary() {
        print("🔍 ErrorManager Summary:")
        print("  - Total errors: \(errorCount)")
        print("  - High severity: \(highSeverityErrorCount)")
        print("  - Recent errors: \(getRecentErrors(count: 5).count)")
    }
}

// MARK: - Error Log Entry

/// Represents a logged error with context and timestamp
struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let error: AppError
    let timestamp: Date
    let context: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - Error Display View

/// SwiftUI view for displaying error information
struct ErrorDisplayView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: iconForSeverity(error.severity))
                    .foregroundColor(colorForSeverity(error.severity))
                    .font(.title2)
                
                Text("Error")
                    .font(.headline)
                    .foregroundColor(colorForSeverity(error.severity))
                
                Spacer()
            }
            
            Text(error.errorDescription ?? "Unknown error occurred")
                .font(.body)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                Button("OK", action: onDismiss)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
    
    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    private func colorForSeverity(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
} 
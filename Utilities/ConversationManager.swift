import Foundation
import SwiftUI

// MARK: - Conversation Message

/// Represents a single message in the AI conversation
struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var isLoading: Bool = false
    
    init(role: MessageRole, content: String, timestamp: Date, isLoading: Bool = false) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isLoading = isLoading
    }
    
    enum MessageRole: String, Codable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "AI"
            case .system: return "System"
            }
        }
        
        var color: Color {
            switch self {
            case .user: return .blue
            case .assistant: return .green
            case .system: return .secondary
            }
        }
    }
}

// MARK: - Conversation State

/// Represents the current state of the conversation
enum ConversationState: Equatable {
    case idle
    case generating
    case error(String)
    
    var isLoading: Bool {
        switch self {
        case .generating: return true
        default: return false
        }
    }
    
    static func == (lhs: ConversationState, rhs: ConversationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.generating, .generating):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Conversation Manager

/// Manages AI conversation history and state for follow-up interactions
class ConversationManager: ObservableObject {
    @Published var messages: [ConversationMessage] = []
    @Published var state: ConversationState = .idle
    @Published var currentInput: String = ""
    @Published var generatedCode: String = ""
    
    private let chatGPTService = ChatGPTService.shared
    private var selectedModel: String = "gpt-4o"
    private var initialComponents: [DetectedComponent] = []
    private var canvasSize: CGSize = .zero
    
    // MARK: - Configuration
    
    func configure(model: String, components: [DetectedComponent], canvasSize: CGSize, initialCode: String = "") {
        self.selectedModel = model
        self.initialComponents = components
        self.canvasSize = canvasSize
        self.generatedCode = initialCode
        
        // Add initial system message if starting fresh conversation
        if messages.isEmpty && !initialCode.isEmpty {
            let systemMessage = ConversationMessage(
                role: .system,
                content: "I've generated initial code for your UI sketch with \(components.count) components. You can ask me to modify, improve, or explain any part of the code.",
                timestamp: Date()
            )
            messages.append(systemMessage)
        }
    }
    
    // MARK: - Conversation Management
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ConversationMessage(
            role: .user,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date()
        )
        
        messages.append(userMessage)
        currentInput = ""
        state = .generating
        
        // Add loading indicator message
        let loadingMessage = ConversationMessage(
            role: .assistant,
            content: "Thinking...",
            timestamp: Date(),
            isLoading: true
        )
        messages.append(loadingMessage)
        
        // Build conversation context for API
        let conversationHistory = buildConversationHistory(includeUserMessage: userMessage)
        
        chatGPTService.generateCode(
            prompt: content,
            model: selectedModel,
            conversation: conversationHistory
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleResponse(result)
            }
        }
    }
    
    private func handleResponse(_ result: Result<String, Error>) {
        // Remove loading message
        if let lastIndex = messages.lastIndex(where: { $0.isLoading }) {
            messages.remove(at: lastIndex)
        }
        
        switch result {
        case .success(let response):
            let assistantMessage = ConversationMessage(
                role: .assistant,
                content: response,
                timestamp: Date()
            )
            messages.append(assistantMessage)
            
            // Update generated code if the response contains code
            if containsCode(response) {
                generatedCode = extractCodeFromResponse(response)
            }
            
            state = .idle
            
        case .failure(let error):
            let errorMessage = ConversationMessage(
                role: .assistant,
                content: formatUserFriendlyError(error),
                timestamp: Date()
            )
            messages.append(errorMessage)
            state = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Error Handling
    
    private func formatUserFriendlyError(_ error: Error) -> String {
        // Import the APIError from Services
        if let apiError = error as? APIError {
            switch apiError {
            case .rateLimited(let retryAfter):
                if let retryAfter = retryAfter {
                    return "I'm temporarily rate-limited. The system will automatically retry in \(Int(retryAfter)) seconds. Please wait a moment..."
                } else {
                    return "I'm experiencing high demand right now. The system is automatically retrying your request. Please wait a moment..."
                }
            
            case .serviceUnavailable(let service):
                return "The \(service) service is temporarily unavailable. I'm automatically trying a backup service for you..."
            
            case .usageLimitExceeded(let used, let limit):
                return "Daily usage limit reached (\(used)/\(limit) requests). The app will reset tomorrow, or contact support for extended access."
            
            case .missingAPIKey(let service):
                return "Configuration issue: \(service) service is not properly set up. Please contact support if this persists."
            
            case .maxRetriesExceeded:
                return "I've tried multiple times but the AI service is currently unavailable. Please try again in a few minutes."
            
            case .invalidResponse:
                return "I received an unexpected response from the AI service. Let me try that again..."
            
            case .noDataReceived:
                return "No response received from the AI service. Please check your internet connection and try again."
            
            case .apiError(let message):
                // Clean up technical error messages for users
                if message.lowercased().contains("rate limit") || message.lowercased().contains("429") {
                    return "I'm experiencing high demand. The system will automatically retry your request..."
                } else if message.lowercased().contains("timeout") {
                    return "The request timed out. I'm automatically retrying with optimized settings..."
                } else if message.lowercased().contains("quota") {
                    return "API quota temporarily exceeded. Trying alternative approach..."
                } else {
                    return "I encountered a technical issue: \(message). The system is working to resolve this automatically."
                }
            }
        }
        
        // Handle network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection detected. Please check your network settings and try again."
            case .timedOut:
                return "Request timed out. The system is automatically retrying with optimized settings..."
            case .cannotConnectToHost:
                return "Cannot connect to the AI service. Please check your internet connection and try again."
            case .networkConnectionLost:
                return "Network connection lost. Please check your connection and try again."
            default:
                return "Network error: \(urlError.localizedDescription). Please check your internet connection."
            }
        }
        
        // Fallback for unknown errors
        let errorDescription = error.localizedDescription
        if errorDescription.lowercased().contains("rate limit") || errorDescription.lowercased().contains("429") {
            return "I'm experiencing high demand. Please wait a moment while I retry your request..."
        } else {
            return "I encountered an unexpected issue: \(errorDescription). Please try again."
        }
    }
    
    // MARK: - Conversation History Building
    
    private func buildConversationHistory(includeUserMessage userMessage: ConversationMessage) -> [[String: String]] {
        var history: [[String: String]] = []
        
        // Add initial context about the UI sketch
        let initialContext = buildInitialContext()
        history.append(["role": "system", "content": initialContext])
        
        // Add existing conversation messages (excluding system messages and loading messages)
        for message in messages where message.role != .system && !message.isLoading {
            history.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        return history
    }
    
    private func buildInitialContext() -> String {
        let layoutDescription = LayoutDescriptor.describe(components: initialComponents, canvasSize: canvasSize)
        
        return """
        You are an expert frontend developer helping to refine and improve generated UI code.
        
        **Original UI Sketch:**
        Canvas Size: \(Int(canvasSize.width)) × \(Int(canvasSize.height)) pixels
        Components: \(initialComponents.count)
        
        \(layoutDescription)
        
        **Current Generated Code:**
        \(generatedCode.isEmpty ? "No code generated yet" : generatedCode)
        
        **Instructions:**
        - Help the user refine, modify, or improve the generated code
        - Answer questions about the code structure and functionality
        - Suggest improvements for accessibility, responsiveness, or design
        - When providing code updates, include the complete HTML file with embedded CSS
        - Be concise but helpful in explanations
        - Focus on practical, implementable suggestions
        """
    }
    
    // MARK: - Code Extraction
    
    private func containsCode(_ response: String) -> Bool {
        return response.contains("<!DOCTYPE html") || 
               response.contains("<html") || 
               response.contains("```html") ||
               response.contains("```css")
    }
    
    private func extractCodeFromResponse(_ response: String) -> String {
        // Try to extract code blocks first
        if let codeBlock = extractCodeBlock(from: response) {
            return codeBlock
        }
        
        // If no code blocks, try to find HTML content
        if response.contains("<!DOCTYPE html") || response.contains("<html") {
            return response
        }
        
        // Fallback: return the response as-is if it seems to contain code
        return response
    }
    
    private func extractCodeBlock(from text: String) -> String? {
        let patterns = [
            "```html\\s*([\\s\\S]*?)```",
            "```\\s*([\\s\\S]*?)```"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    // MARK: - Conversation Actions
    
    func clearConversation() {
        messages.removeAll()
        state = .idle
        currentInput = ""
    }
    
    func exportConversation() -> String {
        return messages.map { message in
            "**\(message.role.displayName)** (\(formatTimestamp(message.timestamp))):\n\(message.content)\n"
        }.joined(separator: "\n")
    }
    
    // MARK: - Utility Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var hasMessages: Bool {
        return !messages.isEmpty
    }
    
    var canSendMessage: Bool {
        return state != .generating && !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Quick Actions
    
    func sendQuickAction(_ action: QuickAction) {
        sendMessage(action.prompt)
    }
}

// MARK: - Quick Actions

enum QuickAction: String, CaseIterable {
    case improveDesign = "Make the design more modern and visually appealing"
    case addResponsive = "Make this responsive for mobile and desktop"
    case improveAccessibility = "Improve accessibility with proper ARIA labels and contrast"
    case addInteractivity = "Add hover effects and smooth transitions"
    case optimizeCode = "Optimize the code for better performance"
    case addDarkMode = "Add dark mode support"
    
    var prompt: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .improveDesign: return "paintbrush"
        case .addResponsive: return "iphone"
        case .improveAccessibility: return "accessibility"
        case .addInteractivity: return "hand.tap"
        case .optimizeCode: return "speedometer"
        case .addDarkMode: return "moon"
        }
    }
    
    var title: String {
        switch self {
        case .improveDesign: return "Improve Design"
        case .addResponsive: return "Make Responsive"
        case .improveAccessibility: return "Add Accessibility"
        case .addInteractivity: return "Add Interactions"
        case .optimizeCode: return "Optimize Code"
        case .addDarkMode: return "Dark Mode"
        }
    }
} 
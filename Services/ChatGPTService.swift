import Foundation

// MARK: - Production API Key Manager

class ProductionAPIKeys {
    static let shared = ProductionAPIKeys()
    private init() {}
    
    // MARK: - API Key Management
    
    func getOpenAIKey() -> String {
        #if DEBUG
        // Development: Use environment variable
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        #else
        // Production: Use embedded key with obfuscation
        return deobfuscateKey(openAIKeyObfuscated)
        #endif
    }
    
    func getAnthropicKey() -> String {
        #if DEBUG
        // Development: Use environment variable  
        return ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        #else
        // Production: Use embedded key with obfuscation
        return deobfuscateKey(anthropicKeyObfuscated)
        #endif
    }
    
    // MARK: - Key Obfuscation (Basic Security)
    
    // TODO: Replace these with your actual API keys before production build
    // Use a simple XOR obfuscation to prevent easy extraction
    private let openAIKeyObfuscated: [UInt8] = [
        // Obfuscated OpenAI API key bytes (implement before production)
        // Example: XOR each character with 0x42
    ]
    
    private let anthropicKeyObfuscated: [UInt8] = [
        // Obfuscated Anthropic API key bytes (implement before production)
        // Example: XOR each character with 0x42
    ]
    
    private func deobfuscateKey(_ obfuscatedKey: [UInt8]) -> String {
        // Simple XOR deobfuscation
        let deobfuscated = obfuscatedKey.map { $0 ^ 0x42 }
        return String(bytes: deobfuscated, encoding: .utf8) ?? ""
    }
    
    // MARK: - Usage Tracking
    
    private let usageKey = "SketchSite_APIUsage"
    private let dailyLimitKey = "SketchSite_DailyLimit"
    
    func trackUsage() {
        let today = Calendar.current.startOfDay(for: Date())
        let usage = UserDefaults.standard.object(forKey: usageKey) as? [String: Int] ?? [:]
        let todayString = ISO8601DateFormatter().string(from: today)
        
        let currentUsage = usage[todayString] ?? 0
        var newUsage = usage
        newUsage[todayString] = currentUsage + 1
        
        UserDefaults.standard.set(newUsage, forKey: usageKey)
        
        print("📊 API Usage tracked: \(currentUsage + 1) requests today")
    }
    
    func canMakeRequest() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let usage = UserDefaults.standard.object(forKey: usageKey) as? [String: Int] ?? [:]
        let todayString = ISO8601DateFormatter().string(from: today)
        
        let currentUsage = usage[todayString] ?? 0
        let dailyLimit = UserDefaults.standard.integer(forKey: dailyLimitKey)
        let limit = dailyLimit > 0 ? dailyLimit : 100 // Default 100 requests per day
        
        return currentUsage < limit
    }
    
    func getTodayUsage() -> (used: Int, limit: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let usage = UserDefaults.standard.object(forKey: usageKey) as? [String: Int] ?? [:]
        let todayString = ISO8601DateFormatter().string(from: today)
        
        let currentUsage = usage[todayString] ?? 0
        let dailyLimit = UserDefaults.standard.integer(forKey: dailyLimitKey)
        let limit = dailyLimit > 0 ? dailyLimit : 100
        
        return (used: currentUsage, limit: limit)
    }
}

// MARK: - Enhanced ChatGPT Service

/// Singleton service for interacting with the OpenAI Chat Completions API.
class ChatGPTService {
    static let shared = ChatGPTService()
    private init() {}

    /// Generates front-end code using OpenAI's GPT or Anthropic Claude model, with optional conversation history.
    /// - Parameters:
    ///   - prompt: The main layout or design prompt or follow-up message.
    ///   - model: The model to use (e.g., gpt-4o, gpt-3.5-turbo, claude-3-opus, etc.).
    ///   - conversation: Optional conversation history for prompt chaining.
    ///   - completion: Completion handler with result of model response.
    func generateCode(prompt: String, model: String = "gpt-4o", conversation: [[String: String]]? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        
        // Check usage limits
        guard ProductionAPIKeys.shared.canMakeRequest() else {
            let usage = ProductionAPIKeys.shared.getTodayUsage()
            completion(.failure(APIError.usageLimitExceeded(used: usage.used, limit: usage.limit)))
            return
        }
        
        let isClaude = model.starts(with: "claude")
        let apiKey = isClaude ? ProductionAPIKeys.shared.getAnthropicKey() : ProductionAPIKeys.shared.getOpenAIKey()
        
        // Validate API key
        guard !apiKey.isEmpty else {
            completion(.failure(APIError.missingAPIKey(service: isClaude ? "Anthropic" : "OpenAI")))
            return
        }
        
        let url = isClaude ? URL(string: "https://api.anthropic.com/v1/messages")! : URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if isClaude {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else {
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        var requestBody: [String: Any] = [:]
        
        if isClaude {
            var messages: [[String: String]] = conversation ?? []
            messages.append(["role": "user", "content": prompt])
            requestBody = [
                "model": model,
                "max_tokens": 4000,
                "messages": messages
            ]
        } else {
            var messages: [[String: String]] = conversation ?? []
            messages.append(["role": "user", "content": prompt])
            requestBody = [
                "model": model,
                "messages": messages,
                "max_tokens": 4000,
                "temperature": 0.7
            ]
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Track usage before making request
        ProductionAPIKeys.shared.trackUsage()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noDataReceived))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if isClaude {
                    if let content = json?["content"] as? [[String: Any]],
                       let firstContent = content.first,
                       let text = firstContent["text"] as? String {
                        completion(.success(text))
                    } else if let error = json?["error"] as? [String: Any],
                             let message = error["message"] as? String {
                        completion(.failure(APIError.apiError(message)))
                    } else {
                        completion(.failure(APIError.invalidResponse))
                    }
                } else {
                    if let choices = json?["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else if let error = json?["error"] as? [String: Any],
                             let message = error["message"] as? String {
                        completion(.failure(APIError.apiError(message)))
                    } else {
                        completion(.failure(APIError.invalidResponse))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - API Errors

enum APIError: LocalizedError, Equatable {
    case missingAPIKey(service: String)
    case usageLimitExceeded(used: Int, limit: Int)
    case apiError(String)
    case invalidResponse
    case noDataReceived
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let service):
            return "\(service) API key not configured"
        case .usageLimitExceeded(let used, let limit):
            return "Daily usage limit exceeded (\(used)/\(limit)). Try again tomorrow or upgrade to Pro."
        case .apiError(let message):
            return "API Error: \(message)"
        case .invalidResponse:
            return "Invalid response from API"
        case .noDataReceived:
            return "No data received from API"
        }
    }
}

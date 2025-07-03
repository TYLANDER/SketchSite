import Foundation

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
        let isClaude = model.starts(with: "claude")
        let apiKey = isClaude ? (ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "") : (ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "")
        let url = isClaude ? URL(string: "https://api.anthropic.com/v1/messages")! : URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if isClaude {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(model, forHTTPHeaderField: "anthropic-version")
        } else {
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        var requestBody: [String: Any] = [:]
        if isClaude {
            // Anthropic Claude expects a different format
            requestBody = [
                "model": model,
                "max_tokens": 2048,
                "messages": (conversation ?? [["role": "user", "content": prompt]])
            ]
        } else {
            requestBody = [
                "model": model,
                "messages": (conversation ?? [["role": "user", "content": prompt]]),
            "temperature": 0.2
        ]
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data {
                print("🔵 Raw response from model:\n\(String(data: data, encoding: .utf8) ?? "Unreadable data")")
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "ChatGPTService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            if isClaude {
                // Parse Anthropic Claude response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let content = (json["content"] as? [[String: Any]])?.compactMap({ $0["text"] as? String }).joined(separator: "\n") {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "ChatGPTService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Claude response"])))
                }
            } else {
                // Parse OpenAI response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
            completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "ChatGPTService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])))
                }
            }
        }
        task.resume()
    }
}

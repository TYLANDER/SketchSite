import Foundation

// Singleton service for interacting with the OpenAI Chat Completions API
class ChatGPTService {
    static let shared = ChatGPTService()
    private init() {}

    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

    /// Generates front-end code using OpenAI's GPT model, with optional user sketch annotations.
    /// - Parameters:
    ///   - prompt: The main layout or design prompt generated from Vision analysis
    ///   - annotations: Freeform user annotations to provide context or intent (e.g., "CTA button here")
    ///   - completion: Completion handler with result of GPT response
    func generateCode(prompt: String, annotations: [String] = [], completion: @escaping (Result<String, Error>) -> Void) {
        // Combine the core layout prompt with user-provided annotations, if any
        var fullPrompt = prompt
        if !annotations.isEmpty {
            let annotationText = annotations.joined(separator: "\n- ")
            fullPrompt += "\n\nUser Annotations:\n- \(annotationText)"
        }

        // Configure the POST request to OpenAI's chat completion endpoint
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4o", // use "gpt-3.5-turbo" if needed
            "messages": [
                ["role": "system", "content": "You are an expert front-end developer."],
                ["role": "user", "content": fullPrompt]
            ],
            "temperature": 0.2
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            // Log raw response for debugging
            if let data = data {
                print("🔵 Raw response from OpenAI:\n\(String(data: data, encoding: .utf8) ?? "Unreadable data")")
            }

            // Attempt to parse GPT response and extract the assistant's message content
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                let parsingError = NSError(domain: "ChatGPTService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse ChatGPT response"])
                completion(.failure(parsingError))
                return
            }

            completion(.success(content))
        }

        task.resume()
    }
}

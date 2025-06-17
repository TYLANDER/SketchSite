

import Foundation

class ChatGPTService {
    static let shared = ChatGPTService()
    private init() {}

    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

    func generateCode(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4o", // use "gpt-3.5-turbo" if needed
            "messages": [
                ["role": "system", "content": "You are an expert front-end developer."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                print("🔵 Raw response from OpenAI:\n\(String(data: data, encoding: .utf8) ?? "Unreadable data")")
            }

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

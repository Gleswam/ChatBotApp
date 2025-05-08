import Foundation

class DeepSeekService {
    private let apiKey: String
    private let baseURL = "https://api.deepseek.com/v1/chat/completions"
    private let session: URLSession
    
    init(apiKey: String, session: URLSession = .shared) {
        guard !apiKey.isEmpty else {
            fatalError("API key cannot be empty")
        }
        self.apiKey = apiKey
        self.session = session
        print("DeepSeekService initialized with API key: \(String(apiKey.prefix(8)))...")
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard !message.isEmpty else {
            throw DeepSeekError.invalidRequest
        }
        print("Sending message: \(message)")
        guard let url = URL(string: baseURL) else {
            print("Error: Invalid URL")
            throw DeepSeekError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": message]
            ],
            "temperature": 0.7
        ]
        // Пример: если бы были вложения, их обработка была бы здесь
        // Сейчас attachments не используются
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DeepSeekError.invalidResponse
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let messageDict = first["message"] as? [String: Any],
              let content = messageDict["content"] as? String else {
            throw DeepSeekError.invalidResponse
        }
        return content
    }
}

enum DeepSeekError: Error {
    case invalidRequest
    case invalidURL
    case invalidResponse
}

struct DeepSeekResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

struct DeepSeekErrorResponse: Codable {
    let error: Error
    
    struct Error: Codable {
        let message: String
    }
} 

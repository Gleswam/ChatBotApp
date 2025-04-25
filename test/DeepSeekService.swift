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
    
    func sendMessage(_ message: String, attachments: [FileAttachment]? = nil) async throws -> String {
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
        
        // Add file attachments if present
        if let attachments = attachments {
            var fileContents: [[String: Any]] = []
            for attachment in attachments {
                let base64Data = attachment.fileData.base64EncodedString()
                fileContents.append([
                    "name": attachment.fileName,
                    "type": attachment.mimeType,
                    "content": base64Data
                ])
            }
            requestBody["files"] = fileContents
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("Request body created successfully")
        } catch {
            print("Error creating request body: \(error)")
            throw DeepSeekError.invalidRequest
        }
        
        do {
            print("Sending request to DeepSeek API...")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid HTTP response")
                throw DeepSeekError.invalidResponse
            }
            
            print("Received response with status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(DeepSeekErrorResponse.self, from: data) {
                    print("API Error: \(errorResponse.error.message)")
                    throw DeepSeekError.apiError(errorResponse.error.message)
                }
                print("Server Error: \(httpResponse.statusCode)")
                throw DeepSeekError.serverError(httpResponse.statusCode)
            }
            
            let chatResponse = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
            print("Successfully decoded response")
            return chatResponse.choices.first?.message.content ?? "No response"
        } catch let error as DeepSeekError {
            print("DeepSeek Error: \(error)")
            throw error
        } catch {
            print("Network Error: \(error)")
            throw DeepSeekError.networkError(error)
        }
    }
}

enum DeepSeekError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case serverError(Int)
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidRequest:
            return "Invalid request format"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
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

import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

extension Message {
    static let appGroup = "group.com.yourapp.chat"
    static let lastMessageKey = "lastMessageCodable"
    
    static func saveLastMessage(_ message: Message) {
        if let data = try? JSONEncoder().encode(message) {
            UserDefaults(suiteName: appGroup)?.set(data, forKey: lastMessageKey)
        }
    }
    
    static func getLastMessage() -> Message? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: lastMessageKey),
              let message = try? JSONDecoder().decode(Message.self, from: data) else {
            return nil
        }
        return message
    }
} 

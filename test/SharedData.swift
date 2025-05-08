import Foundation

struct SharedData {
    static let appGroupIdentifier = "group.com.yourapp.chat"
    static let lastMessageKey = "lastMessageCodable"
    
    static var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    static func saveLastMessage(_ message: Message) {
        if let data = try? JSONEncoder().encode(message) {
            userDefaults?.set(data, forKey: lastMessageKey)
        }
    }
    
    static func getLastMessage() -> Message? {
        guard let data = userDefaults?.data(forKey: lastMessageKey),
              let message = try? JSONDecoder().decode(Message.self, from: data) else {
            return nil
        }
        return message
    }
} 
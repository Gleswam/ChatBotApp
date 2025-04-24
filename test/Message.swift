import Foundation
import SwiftData

@Model
final class Message {
    var content: String
    var isUser: Bool
    var timestamp: Date
    
    init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

extension Message: Identifiable {} 
import Foundation
import SwiftData

@Model
final class FileAttachment {
    var fileName: String
    var fileData: Data
    var mimeType: String
    var message: Message?
    
    init(fileName: String, fileData: Data, mimeType: String) {
        self.fileName = fileName
        self.fileData = fileData
        self.mimeType = mimeType
    }
}

@Model
final class Message {
    var content: String
    var isUser: Bool
    var timestamp: Date
    @Relationship(deleteRule: .cascade) var attachments: [FileAttachment]?
    
    init(content: String, isUser: Bool, timestamp: Date = Date(), attachments: [FileAttachment]? = nil) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.attachments = attachments
    }
}

extension Message: Identifiable {}
extension FileAttachment: Identifiable {} 
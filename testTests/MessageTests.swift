import XCTest
@testable import test

final class MessageTests: XCTestCase {
    func testMessageInitialization() {
        // Given
        let content = "Test message"
        let isUser = true
        let timestamp = Date()
        
        // When
        let message = Message(content: content, isUser: isUser, timestamp: timestamp)
        
        // Then
        XCTAssertEqual(message.content, content)
        XCTAssertEqual(message.isUser, isUser)
        XCTAssertEqual(message.timestamp, timestamp)
    }
    
    func testMessageDefaultTimestamp() {
        // Given
        let content = "Test message"
        let isUser = false
        
        // When
        let message = Message(content: content, isUser: isUser)
        
        // Then
        XCTAssertEqual(message.content, content)
        XCTAssertEqual(message.isUser, isUser)
        XCTAssertNotNil(message.timestamp)
    }
} 
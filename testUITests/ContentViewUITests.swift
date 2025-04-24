import XCTest

final class ContentViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    func testInitialState() {
        // Then
        XCTAssertTrue(app.textFields["Type a message..."].exists)
        XCTAssertTrue(app.buttons["paperplane.fill"].exists)
        XCTAssertFalse(app.buttons["paperplane.fill"].isEnabled)
    }
    
    func testSendMessage() {
        // Given
        let textField = app.textFields["Type a message..."]
        let sendButton = app.buttons["paperplane.fill"]
        
        // When
        textField.tap()
        textField.typeText("Hello, how are you?")
        
        // Then
        XCTAssertTrue(sendButton.isEnabled)
        
        // When
        sendButton.tap()
        
        // Then
        XCTAssertEqual(textField.value as? String, "")
        XCTAssertFalse(sendButton.isEnabled)
        
        // Wait for response
        let responsePredicate = NSPredicate(format: "exists == true")
        let responseExpectation = expectation(for: responsePredicate, evaluatedWith: app.staticTexts["This is a test response"], handler: nil)
        wait(for: [responseExpectation], timeout: 5.0)
    }
    
    func testMessageBubbleAppearance() {
        // Given
        let textField = app.textFields["Type a message..."]
        let sendButton = app.buttons["paperplane.fill"]
        
        // When
        textField.tap()
        textField.typeText("Test message")
        sendButton.tap()
        
        // Then
        let messageBubble = app.staticTexts["Test message"]
        XCTAssertTrue(messageBubble.exists)
        
        // Wait for response
        let responsePredicate = NSPredicate(format: "exists == true")
        let responseExpectation = expectation(for: responsePredicate, evaluatedWith: app.staticTexts["This is a test response"], handler: nil)
        wait(for: [responseExpectation], timeout: 5.0)
    }
    
    func testEmptyMessage() {
        // Given
        let textField = app.textFields["Type a message..."]
        let sendButton = app.buttons["paperplane.fill"]
        
        // When
        textField.tap()
        textField.typeText("")
        
        // Then
        XCTAssertFalse(sendButton.isEnabled)
    }
    
    func testLongMessage() {
        // Given
        let textField = app.textFields["Type a message..."]
        let sendButton = app.buttons["paperplane.fill"]
        let longMessage = String(repeating: "a", count: 1000)
        
        // When
        textField.tap()
        textField.typeText(longMessage)
        
        // Then
        XCTAssertTrue(sendButton.isEnabled)
        
        // When
        sendButton.tap()
        
        // Then
        XCTAssertEqual(textField.value as? String, "")
        XCTAssertFalse(sendButton.isEnabled)
    }
    
    func testSpecialCharacters() {
        // Given
        let textField = app.textFields["Type a message..."]
        let sendButton = app.buttons["paperplane.fill"]
        let message = "Hello! 😊"
        
        // When
        textField.tap()
        textField.typeText(message)
        sendButton.tap()
        
        // Then
        let messageBubble = app.staticTexts[message]
        XCTAssertTrue(messageBubble.exists)
    }
    
    func testMultipleMessages() {
        // Given
        let textField = app.textFields["Type a message..."]
        let sendButton = app.buttons["paperplane.fill"]
        
        // When
        for i in 1...3 {
            textField.tap()
            textField.typeText("Message \(i)")
            sendButton.tap()
            
            // Wait for response
            let responsePredicate = NSPredicate(format: "exists == true")
            let responseExpectation = expectation(for: responsePredicate, evaluatedWith: app.staticTexts["This is a test response"], handler: nil)
            wait(for: [responseExpectation], timeout: 5.0)
        }
        
        // Then
        for i in 1...3 {
            XCTAssertTrue(app.staticTexts["Message \(i)"].exists)
        }
    }
    
    func testErrorHandling() {
        // Given
        let textField = app.textFields["Type a message..."]
        let sendButton = app.buttons["paperplane.fill"]
        
        // When
        textField.tap()
        textField.typeText("Error test")
        sendButton.tap()
        
        // Then
        let errorPredicate = NSPredicate(format: "exists == true")
        let errorExpectation = expectation(for: errorPredicate, evaluatedWith: app.staticTexts["Network error. Please check your connection"], handler: nil)
        wait(for: [errorExpectation], timeout: 5.0)
    }
} 
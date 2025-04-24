import XCTest
@testable import test

final class ChatGPTServiceTests: XCTestCase {
    var sut: ChatGPTService!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        sut = ChatGPTService(apiKey: Config.testApiKey, session: mockURLSession)
    }
    
    override func tearDown() {
        sut = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    func testSendMessageWithValidResponse() async throws {
        // Given
        let message = "Hello, how are you?"
        let expectedResponse = "I'm doing well, thank you!"
        mockURLSession.mockResponse = try JSONEncoder().encode(ChatGPTResponse(choices: [
            ChatGPTResponse.Choice(message: ChatGPTResponse.Message(content: expectedResponse))
        ]))
        
        // When
        let response = try await sut.sendMessage(message)
        
        // Then
        XCTAssertEqual(response, expectedResponse)
        XCTAssertEqual(mockURLSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mockURLSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer \(Config.testApiKey)")
    }
    
    func testSendMessageWithInvalidAPIKey() async {
        // Given
        sut = ChatGPTService(apiKey: "invalid-key", session: mockURLSession)
        let message = "Hello"
        mockURLSession.mockError = URLError(.badServerResponse)
        
        // When/Then
        do {
            _ = try await sut.sendMessage(message)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ChatGPTError)
        }
    }
    
    func testSendMessageWithInvalidResponse() async {
        // Given
        let message = "Hello"
        mockURLSession.mockResponse = "Invalid JSON".data(using: .utf8)!
        
        // When/Then
        do {
            _ = try await sut.sendMessage(message)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ChatGPTError)
        }
    }
    
    func testSendMessageWithServerError() async {
        // Given
        let message = "Hello"
        mockURLSession.mockResponse = try JSONEncoder().encode(ChatGPTErrorResponse(error: ChatGPTErrorResponse.Error(message: "Invalid API key")))
        mockURLSession.mockStatusCode = 401
        
        // When/Then
        do {
            _ = try await sut.sendMessage(message)
            XCTFail("Expected error to be thrown")
        } catch let error as ChatGPTError {
            if case .apiError(let message) = error {
                XCTAssertEqual(message, "Invalid API key")
            } else {
                XCTFail("Expected API error")
            }
        } catch {
            XCTFail("Expected ChatGPTError")
        }
    }
    
    func testSendEmptyMessage() async {
        // Given
        let message = ""
        
        // When/Then
        do {
            _ = try await sut.sendMessage(message)
            XCTFail("Expected error to be thrown")
        } catch let error as ChatGPTError {
            if case .invalidRequest = error {
                // Success
            } else {
                XCTFail("Expected invalidRequest error")
            }
        } catch {
            XCTFail("Expected ChatGPTError")
        }
    }
    
    func testSendMessageWithLongResponse() async throws {
        // Given
        let message = "Tell me a long story"
        let longResponse = String(repeating: "This is a long response. ", count: 50)
        mockURLSession.mockResponse = try JSONEncoder().encode(ChatGPTResponse(choices: [
            ChatGPTResponse.Choice(message: ChatGPTResponse.Message(content: longResponse))
        ]))
        
        // When
        let response = try await sut.sendMessage(message)
        
        // Then
        XCTAssertEqual(response, longResponse)
    }
    
    func testSendMessageWithSpecialCharacters() async throws {
        // Given
        let message = "Hello! How are you? 😊"
        let expectedResponse = "I'm doing well! 😊"
        mockURLSession.mockResponse = try JSONEncoder().encode(ChatGPTResponse(choices: [
            ChatGPTResponse.Choice(message: ChatGPTResponse.Message(content: expectedResponse))
        ]))
        
        // When
        let response = try await sut.sendMessage(message)
        
        // Then
        XCTAssertEqual(response, expectedResponse)
    }
}

// MARK: - Mock URLSession
class MockURLSession: URLSession, @unchecked Sendable {
    var mockResponse: Data?
    var mockError: Error?
    var mockStatusCode: Int = 200
    var lastRequest: URLRequest?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse else {
            throw ChatGPTError.invalidResponse
        }
        
        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: mockStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (response, httpResponse)
    }
} 

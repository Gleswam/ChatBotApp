//
//  ContentView.swift
//  test
//
//  Created by Gleswam on 6. 4. 2025..
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Message.timestamp) private var messages: [Message]
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private let deepSeekService: ChatGPTService
    
    init() {
        self.deepSeekService = ChatGPTService(apiKey: Config.apiKey)
    }
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
            
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                    .onSubmit {
                        if !newMessage.isEmpty && !isLoading {
                            sendMessage()
                        }
                    }
                
                Button(action: sendMessage) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(newMessage.isEmpty || isLoading)
            }
            .padding()
        }
        .animation(.easeInOut, value: isLoading)
        .animation(.easeInOut, value: errorMessage)
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let userMessage = Message(content: newMessage, isUser: true)
        modelContext.insert(userMessage)
        
        let messageToSend = newMessage
        newMessage = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await deepSeekService.sendMessage(messageToSend)
                await MainActor.run {
                    let botMessage = Message(content: response, isUser: false)
                    modelContext.insert(botMessage)
                    isLoading = false
                }
            } catch let error as ChatGPTError {
                await MainActor.run {
                    switch error {
                    case .invalidURL:
                        errorMessage = "Invalid URL configuration"
                    case .invalidRequest:
                        errorMessage = "Invalid request format"
                    case .invalidResponse:
                        errorMessage = "Invalid response from server"
                    case .serverError(let code):
                        errorMessage = "Server error: \(code)"
                    case .apiError(let message):
                        errorMessage = "API error: \(message)"
                    case .networkError:
                        errorMessage = "Network error. Please check your connection"
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "An unexpected error occurred"
                    isLoading = false
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(20)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Message.self, inMemory: true)
}

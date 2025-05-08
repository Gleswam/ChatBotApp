//
//  ContentView.swift
//  test
//
//  Created by Gleswam on 6. 4. 2025..
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import UIKit

struct NeonGradient: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.7), color.opacity(0.3), color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0)
    }
}

struct PulsingAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct ContentView: View {
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSettings: Bool = false
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    
    private let deepSeekService: DeepSeekService
    
    init() {
        self.deepSeekService = DeepSeekService(apiKey: Config.apiKey)
        // Загрузка истории чата при инициализации
        if let loaded = ChatHistory.load() {
            _messages = State(initialValue: loaded)
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("AI Chat")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                // Messages
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
                
                // Input area
                VStack(spacing: 0) {
                    // Message input
                    HStack {
                        TextField("Type a message...", text: $newMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .foregroundColor(.black)
                            .disabled(isProcessing)
                            .onSubmit {
                                if !newMessage.isEmpty && !isProcessing {
                                    sendMessage()
                                }
                            }
                        
                        Button(action: sendMessage) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(newMessage.isEmpty || isProcessing)
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.3))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onClearHistory: clearHistory)
                .presentationDetents([.height(200)])
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: messages) { _ in
            ChatHistory.save(messages)
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let userMessage = Message(content: trimmedMessage, isUser: true, timestamp: Date())
        messages.append(userMessage)
        Message.saveLastMessage(userMessage)
        newMessage = ""
        
        isProcessing = true
        Task {
            do {
                let response = try await deepSeekService.sendMessage(trimmedMessage)
                await MainActor.run {
                    let aiMessage = Message(content: response, isUser: false, timestamp: Date())
                    messages.append(aiMessage)
                    Message.saveLastMessage(aiMessage)
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func clearHistory() {
        messages.removeAll()
        showSettings = false
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
                .background(
                    message.isUser ?
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [.gray.opacity(0.2), .gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(20)
                .modifier(NeonGradient(color: message.isUser ? .blue : .purple))
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct SettingsView: View {
    let onClearHistory: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Button(action: { showConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear Chat History")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Clear History", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                onClearHistory()
            }
        } message: {
            Text("Are you sure you want to clear all chat history? This action cannot be undone.")
        }
    }
}

extension URL {
    func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream"
    }
}

struct ChatHistory {
    static let key = "chatHistory"
    static func save(_ messages: [Message]) {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    static func load() -> [Message]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([Message].self, from: data) else {
            return nil
        }
        return messages
    }
}

#Preview {
    ContentView()
}


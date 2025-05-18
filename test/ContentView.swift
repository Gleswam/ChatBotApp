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
import UserNotifications

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

struct LoadingDots: View {
    @State private var phase: Int = 0
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

struct ContentView: View {
    @AppStorage("pendingQuickCommand") private var pendingQuickCommand: String = ""
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSettings: Bool = false
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
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
            // Красивый градиентный фон
            LinearGradient(
                colors: colorScheme == .dark ? [Color.black, Color.purple.opacity(0.7)] : [Color.white, Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Text("AI Chat")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                .padding()
                .background(Color.clear)
                
                // Messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    onDelete: message.isUser ? deleteMessage : nil
                                )
                                .id(message.id)
                                .transition(.move(edge: message.isUser ? .trailing : .leading).combined(with: .opacity))
                                .animation(.spring(), value: messages)
                            }
                            if isProcessing {
                                HStack {
                                    Spacer()
                                    LoadingDots()
                                        .accessibilityLabel("Loading response")
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages) { _ in
                        withAnimation {
                            if let last = messages.last {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                
                // Input area
                VStack(spacing: 0) {
                    HStack {
                        TextField("Например: 'Погода сейчас', 'Новости', 'Скажи привет на японском'...", text: $newMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(10)
                            .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                            .cornerRadius(20)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .disabled(isProcessing)
                            .onSubmit {
                                if !newMessage.isEmpty && !isProcessing {
                                    sendMessage()
                                }
                            }
                        
                        Button(action: sendMessage) {
                            if isProcessing {
                                LoadingDots()
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
                .background(Color.clear)
            }
        }
        .onChange(of: messages) { _ in
            ChatHistory.save(messages)
        }
        .onAppear {
            if !pendingQuickCommand.isEmpty {
                handleQuickCommand(pendingQuickCommand)
                pendingQuickCommand = ""
            }
        }
        .onChange(of: pendingQuickCommand) { newValue in
            if !newValue.isEmpty {
                handleQuickCommand(newValue)
                pendingQuickCommand = ""
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chat screen")
        .accessibilityHint("Swipe messages left or right for actions, double tap to copy")
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let userMessage = Message(content: trimmedMessage, isUser: true, timestamp: Date())
        withAnimation {
            messages.append(userMessage)
        }
        Message.saveLastMessage(userMessage)
        newMessage = ""
        
        isProcessing = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred() // Виброотклик
        Task {
            do {
                let response = try await deepSeekService.sendMessage(trimmedMessage)
                await MainActor.run {
                    let aiMessage = Message(content: response, isUser: false, timestamp: Date())
                    withAnimation {
                        messages.append(aiMessage)
                    }
                    Message.saveLastMessage(aiMessage)
                    isProcessing = false
                    sendLocalNotification(with: response)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred() // Виброотклик
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
    
    private func handleQuickCommand(_ command: String) {
        isProcessing = true
        Task {
            do {
                let response = try await deepSeekService.sendMessage(command)
                await MainActor.run {
                    let aiMessage = Message(content: response, isUser: false, timestamp: Date())
                    withAnimation {
                        messages.append(aiMessage)
                    }
                    Message.saveLastMessage(aiMessage)
                    isProcessing = false
                    sendLocalNotification(with: response)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred() // Виброотклик
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
    
    private func sendLocalNotification(with text: String) {
        let content = UNMutableNotificationContent()
        content.title = "AI Chat"
        content.body = text
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    private func deleteMessage(_ message: Message) {
        withAnimation {
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages.remove(at: index)
                ChatHistory.save(messages)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
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


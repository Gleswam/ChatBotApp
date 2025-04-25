//
//  ContentView.swift
//  test
//
//  Created by Gleswam on 6. 4. 2025..
//

import SwiftUI
import SwiftData
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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Message.timestamp) private var messages: [Message]
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedFiles: [FileAttachment] = []
    @State private var isFilePickerPresented: Bool = false
    @State private var isImagePickerPresented: Bool = false
    @State private var isCameraPresented: Bool = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showImageSourceAlert: Bool = false
    @State private var isRecording: Bool = false
    @State private var showSettings: Bool = false
    
    private let deepSeekService: DeepSeekService
    
    init() {
        self.deepSeekService = DeepSeekService(apiKey: Config.apiKey)
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
                
                // Attachments preview
                if !selectedFiles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedFiles) { file in
                                FileAttachmentView(file: file) {
                                    if let index = selectedFiles.firstIndex(where: { $0.id == file.id }) {
                                        selectedFiles.remove(at: index)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 60)
                }
                
                // Input area
                VStack(spacing: 0) {
                    // Action buttons
                    HStack {
                        Button(action: { showImageSourceAlert = true }) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                        }
                        
                        Button(action: { isRecording.toggle() }) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                        }
                        .modifier(PulsingAnimation())
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "face.smiling")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Message input
                    HStack {
                        TextField("Type a message...", text: $newMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                            .disabled(isLoading)
                            .onSubmit {
                                if !newMessage.isEmpty && !isLoading {
                                    sendMessage()
                                }
                            }
                        
                        Button(action: sendMessage) {
                            if isLoading {
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
                        .disabled(newMessage.isEmpty || isLoading)
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.3))
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            do {
                let urls = try result.get()
                for url in urls {
                    let data = try Data(contentsOf: url)
                    let fileName = url.lastPathComponent
                    let mimeType = url.mimeType()
                    let attachment = FileAttachment(fileName: fileName, fileData: data, mimeType: mimeType)
                    selectedFiles.append(attachment)
                }
            } catch {
                errorMessage = "Error loading file: \(error.localizedDescription)"
            }
        }
        .photosPicker(isPresented: $isImagePickerPresented, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            if let item = newItem {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                handleSelectedImage(image)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .alert("Choose Image Source", isPresented: $showImageSourceAlert) {
            Button("Camera") {
                isCameraPresented = true
            }
            Button("Photo Library") {
                isImagePickerPresented = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onClearHistory: clearHistory)
                .presentationDetents([.height(200)])
        }
    }
    
    private func handleSelectedImage(_ image: UIImage) {
        do {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let fileName = "image_\(Date().timeIntervalSince1970).jpg"
                let attachment = FileAttachment(fileName: fileName, fileData: imageData, mimeType: "image/jpeg")
                selectedFiles.append(attachment)
            } else {
                throw NSError(domain: "ImageProcessing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
            }
        } catch {
            errorMessage = "Error processing image: \(error.localizedDescription)"
        }
        selectedImage = nil
        selectedItem = nil
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let userMessage = Message(content: newMessage, isUser: true, attachments: selectedFiles)
        modelContext.insert(userMessage)
        
        let messageToSend = newMessage
        let filesToSend = selectedFiles
        newMessage = ""
        selectedFiles = []
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await deepSeekService.sendMessage(messageToSend, attachments: filesToSend)
                await MainActor.run {
                    let botMessage = Message(content: response, isUser: false)
                    modelContext.insert(botMessage)
                    isLoading = false
                }
            } catch let error as DeepSeekError {
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
    
    private func clearHistory() {
        for message in messages {
            modelContext.delete(message)
        }
        showSettings = false
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct FileAttachmentView: View {
    let file: FileAttachment
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            if file.mimeType.starts(with: "image/") {
                if let uiImage = UIImage(data: file.fileData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Image(systemName: "doc.fill")
                    .foregroundColor(.white)
            }
            
            Text(file.fileName)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            if let attachments = message.attachments {
                ForEach(attachments) { file in
                    if file.mimeType.starts(with: "image/") {
                        if let uiImage = UIImage(data: file.fileData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .modifier(NeonGradient(color: message.isUser ? .blue : .purple))
                        }
                    } else {
                        FileAttachmentView(file: file) {}
                    }
                }
            }
            
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

#Preview {
    ContentView()
        .modelContainer(for: [Message.self, FileAttachment.self], inMemory: true)
}

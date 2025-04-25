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
    
    private let deepSeekService: DeepSeekService
    
    init() {
        self.deepSeekService = DeepSeekService(apiKey: Config.apiKey)
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
            
            HStack {
                Menu {
                    Button(action: { isFilePickerPresented = true }) {
                        Label("File", systemImage: "doc")
                    }
                    
                    Button(action: { showImageSourceAlert = true }) {
                        Label("Image", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .disabled(isLoading)
                
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
        .animation(.easeInOut, value: selectedFiles)
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
                    .foregroundColor(.blue)
            }
            
            Text(file.fileName)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
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
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                
                if !message.isUser {
                    Spacer()
                }
            }
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

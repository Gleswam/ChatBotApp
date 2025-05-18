import SwiftUI

struct MessageBubble: View {
    let message: Message
    let onDelete: ((Message) -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    init(message: Message, onDelete: ((Message) -> Void)? = nil) {
        self.message = message
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            // Основной контейнер сообщения
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
                        colors: [.gray.opacity(0.3), .gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.primary)
                .cornerRadius(20)
                .modifier(NeonGradient(color: message.isUser ? .blue : .purple))
                .shadow(radius: 4)
                // Добавляем контекстное меню при долгом нажатии
                .contextMenu {
                    Button(action: copyMessage) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    Button(action: shareMessage) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    if message.isUser {
                        Button(role: .destructive, action: deleteMessage) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                // Добавляем поддержку VoiceOver
                .accessibilityElement(children: .combine)
                .accessibilityLabel(message.isUser ? "Your message" : "AI response")
                .accessibilityHint("Long press for more options")
                .accessibilityAddTraits(.isStaticText)
                .accessibilityAction(.default) {
                    copyMessage()
                }
                .accessibilityAction(named: "Copy") {
                    copyMessage()
                }
                .accessibilityAction(named: "Share") {
                    shareMessage()
                }
                .accessibilityAction(named: "Delete") {
                    if message.isUser {
                        deleteMessage()
                    }
                }
            
            if !message.isUser {
                Spacer()
            }
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    // MARK: - Actions
    
    private func copyMessage() {
        UIPasteboard.general.string = message.content
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func shareMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [message.content],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func deleteMessage() {
        withAnimation {
            onDelete?(message)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

//// MARK: - Preview
//struct MessageBubble_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack {
//            MessageBubble(
//                message: Message(
//                    content: "Hello, this is a user message!",
//                    isUser: true
//                ),
//                onDelete: { _ in }
//            )
//            MessageBubble(
//                message: Message(
//                    content: "This is an AI response to your message.",
//                    isUser: false
//                )
//            )
//        }
//        .padding()
//        .previewLayout(.sizeThatFits)
//    }
//} 

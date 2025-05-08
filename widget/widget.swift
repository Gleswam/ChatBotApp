//
//  widget.swift
//  widget
//
//  Created by Gleswam on 8. 5. 2025..
//

import WidgetKit
import SwiftUI
import AppIntents

struct QuickCommand: Identifiable {
    let id = UUID()
    let title: String
    let command: String
    let icon: String
}

struct Provider: TimelineProvider {
    let commands = [
        QuickCommand(title: "Погода по геолокации", command: "Погода сейчас в моём городе", icon: "cloud.sun.fill"),
        QuickCommand(title: "Новости по геолокации", command: "Новости в моём регионе", icon: "newspaper.fill"),
        QuickCommand(title: "Приветствие на случайном языке", command: "Скажи привет на случайном языке", icon: "globe")
    ]
    
    func placeholder(in context: Context) -> ChatEntry {
        ChatEntry(date: Date(), commands: commands, lastMessage: Message.getLastMessage())
    }

    func getSnapshot(in context: Context, completion: @escaping (ChatEntry) -> ()) {
        let entry = ChatEntry(date: Date(), commands: commands, lastMessage: Message.getLastMessage())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ChatEntry>) -> ()) {
        let entry = ChatEntry(date: Date(), commands: commands, lastMessage: Message.getLastMessage())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct ChatEntry: TimelineEntry {
    let date: Date
    let commands: [QuickCommand]
    let lastMessage: Message?
}

struct widgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Последнее сообщение
            if let lastMessage = entry.lastMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Последнее сообщение")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(lastMessage.content)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.bottom, 4)
                }
                .padding(.bottom, 4)
            }
            
            // Быстрые команды
            Text("Быстрые команды")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(entry.commands) { command in
                Button(action: {
                    if let encodedCommand = command.command.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: "aichat://command?text=\(encodedCommand)") {
                        openURL(url)
                    }
                }) {
                    HStack {
                        Image(systemName: command.icon)
                            .foregroundColor(.white)
                        Text(command.title)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

struct widget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
        }
        .configurationDisplayName("AI Chat")
        .description("Чат с быстрыми командами")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    widget()
} timeline: {
    ChatEntry(date: .now, commands: [
        QuickCommand(title: "Погода по геолокации", command: "Погода сейчас в моём городе", icon: "cloud.sun.fill"),
        QuickCommand(title: "Новости по геолокации", command: "Новости в моём регионе", icon: "newspaper.fill"),
        QuickCommand(title: "Приветствие на случайном языке", command: "Скажи привет на случайном языке", icon: "globe")
    ], lastMessage: Message(content: "Привет! Как я могу помочь?", isUser: false))
}

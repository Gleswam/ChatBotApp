import WidgetKit
import SwiftUI

struct NewsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NewsEntry {
        NewsEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (NewsEntry) -> ()) {
        completion(NewsEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsEntry>) -> ()) {
        let entry = NewsEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct NewsEntry: TimelineEntry {
    let date: Date
}

struct NewsWidgetEntryView: View {
    var entry: NewsWidgetProvider.Entry
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Новости по геолокации")
                .font(.headline)
                .foregroundColor(.white)
            Button(action: {
                let text = "Новости в моём регионе"
                if let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "aichat://command?text=\(encoded)") {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "newspaper.fill").foregroundColor(.white)
                    Text("Узнать новости")
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.8))
    }
}

struct NewsWidget: Widget {
    let kind: String = "NewsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewsWidgetProvider()) { entry in
            NewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Новости")
        .description("Новости по геолокации")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
} 
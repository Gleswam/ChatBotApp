import WidgetKit
import SwiftUI

struct GreetingWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GreetingEntry {
        GreetingEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (GreetingEntry) -> ()) {
        completion(GreetingEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<GreetingEntry>) -> ()) {
        let entry = GreetingEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct GreetingEntry: TimelineEntry {
    let date: Date
}

struct GreetingWidgetEntryView: View {
    var entry: GreetingWidgetProvider.Entry
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Приветствие на случайном языке")
                .font(.headline)
                .foregroundColor(.white)
            Button(action: {
                let text = "Скажи привет на случайном языке"
                if let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "aichat://command?text=\(encoded)") {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "globe").foregroundColor(.white)
                    Text("Случайное приветствие")
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.green.opacity(0.8))
    }
}

struct GreetingWidget: Widget {
    let kind: String = "GreetingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GreetingWidgetProvider()) { entry in
            GreetingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Приветствие")
        .description("Приветствие на случайном языке")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
} 
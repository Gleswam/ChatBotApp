import WidgetKit
import SwiftUI

struct WeatherWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> ()) {
        completion(WeatherEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> ()) {
        let entry = WeatherEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct WeatherEntry: TimelineEntry {
    let date: Date
}

struct WeatherWidgetEntryView: View {
    var entry: WeatherWidgetProvider.Entry
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Погода по геолокации")
                .font(.headline)
                .foregroundColor(.white)
            Button(action: {
                let text = "Погода сейчас в моём городе"
                if let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "aichat://command?text=\(encoded)") {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "cloud.sun.fill").foregroundColor(.white)
                    Text("Узнать погоду")
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.8))
    }
}

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherWidgetProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Погода")
        .description("Погода по геолокации")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
} 
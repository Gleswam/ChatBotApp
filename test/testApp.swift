//
//  testApp.swift
//  test
//
//  Created by Gleswam on 6. 4. 2025..
//

import SwiftUI
import SwiftData

@main
struct testApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([Message.self, FileAttachment.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

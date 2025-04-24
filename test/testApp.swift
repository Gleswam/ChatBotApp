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
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([Message.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

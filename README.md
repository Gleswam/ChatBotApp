# DeepSeek Chat App

A simple iOS chat application that uses the DeepSeek API for AI-powered conversations.

## Features

- Real-time chat interface
- Integration with DeepSeek AI
- Message persistence using SwiftData
- Error handling and loading states
- Clean and modern UI

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- DeepSeek API key

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Add your DeepSeek API key in `Config.swift`
4. Build and run the project

## Configuration

Create a `Config.swift` file with your API key:

```swift
import Foundation

enum Config {
    static let apiKey: String = "your-api-key-here"
}
```

## Usage

1. Launch the app
2. Type your message in the text field
3. Press the send button or hit return
4. Wait for the AI's response

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
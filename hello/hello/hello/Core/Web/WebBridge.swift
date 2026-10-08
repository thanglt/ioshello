//
//  WebBridge.swift
//  hello
//

import Foundation
import OSLog
import WebKit

/// Receives the page's `window.ReactNativeWebView.postMessage(JSON.stringify(msg))` calls.
/// The page was written for a React Native host, so we provide that object and forward
/// each message to a `WKScriptMessageHandler`.
enum WebBridge {
    static let handlerName = "nativeBridge"

    static let script = """
        window.ReactNativeWebView = window.ReactNativeWebView || {
          postMessage: (data) => window.webkit.messageHandlers.\(handlerName).postMessage(String(data))
        };
        """

    /// A command sent by the page as `{ "command": "...", ... }`.
    enum Command: Equatable {
        /// The page's back button on its first screen (`msg.command = 'back'`): close the web view.
        case back
        case unknown(String)

        init(_ name: String) {
            switch name {
            case "back": self = .back
            default: self = .unknown(name)
            }
        }
    }

    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "hello", category: "WebBridge")

    /// Parses a message body such as `{"command":"back"}`. Returns `nil` for anything else.
    static func command(from body: Any) -> Command? {
        guard
            let text = body as? String,
            let data = text.data(using: .utf8),
            let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let name = message["command"] as? String
        else {
            logger.warning("Ignored web message: \(String(describing: body), privacy: .public)")
            return nil
        }
        return Command(name)
    }
}

/// `WKUserContentController` retains its handlers, so listeners go through this proxy to
/// avoid a retain cycle with the `WKWebView` that owns the controller.
final class WebBridgeMessageHandler: NSObject, WKScriptMessageHandler {
    var onCommand: ((WebBridge.Command) -> Void)?

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let command = WebBridge.command(from: message.body) else { return }
        onCommand?(command)
    }
}

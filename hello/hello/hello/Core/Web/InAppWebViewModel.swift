//
//  InAppWebViewModel.swift
//  hello
//

import Foundation
import Observation
import OSLog
import WebKit

/// Owns a `WKWebView`.
/// - Main-frame GET navigations are re-issued with `Accept-Language`, because WebKit only
///   sends our header on requests we load ourselves.
/// - The page talks to its host through `window.ReactNativeWebView.postMessage`; a
///   `{"command":"back"}` message (the page's own back button) asks to close the screen.
@Observable
final class InAppWebViewModel: NSObject {
    let request: URLRequest
    let userAgentPrefix: String
    @ObservationIgnored let webView: WKWebView

    private(set) var isLoading = false
    private(set) var estimatedProgress = 0.0
    private(set) var isCloseRequested = false

    @ObservationIgnored private var observations: [NSKeyValueObservation] = []
    @ObservationIgnored private var hasLoaded = false

    init(request: URLRequest, userAgentPrefix: String) {
        self.request = request
        self.userAgentPrefix = userAgentPrefix
        let bridge = WebBridgeMessageHandler()
        let configuration = JapaneseWebSupport.makeConfiguration()
        configuration.userContentController.addUserScript(
            WKUserScript(source: WebBridge.script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        configuration.userContentController.add(bridge, name: WebBridge.handlerName)
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        bridge.onCommand = { [weak self] command in
            self?.handle(command)
        }
        observeWebView()
    }

    /// Loads the first page once, even if the view's `.task` runs again.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        let defaultUserAgent = try? await webView.evaluateJavaScript("navigator.userAgent") as? String
        webView.customUserAgent = [userAgentPrefix, defaultUserAgent]
            .compactMap { $0 }
            .joined(separator: " ")
        webView.load(JapaneseWebSupport.localized(request))
    }

    private func handle(_ command: WebBridge.Command) {
        switch command {
        case .back:
            isCloseRequested = true
        case .unknown(let name):
            WebBridge.logger.info("Unhandled web command: \(name, privacy: .public)")
        }
    }

    /// KVO fires on the main thread for `WKWebView`, which is main-actor-only.
    private func observeWebView() {
        observations = [
            webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
                MainActor.assumeIsolated {
                    self?.isLoading = webView.isLoading
                }
            },
            webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                MainActor.assumeIsolated {
                    self?.estimatedProgress = webView.estimatedProgress
                }
            },
        ]
    }

    private static func isWebURL(_ url: URL?) -> Bool {
        guard let scheme = url?.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    /// Fragment-only changes (`#…`) must stay in-page instead of reloading.
    private static func isSameDocument(_ url: URL, as currentURL: URL?) -> Bool {
        guard url.fragment != nil, let currentURL else { return false }
        return withoutFragment(url) == withoutFragment(currentURL)
    }

    private static func withoutFragment(_ url: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.url
    }
}

extension InAppWebViewModel: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        let request = navigationAction.request
        guard
            navigationAction.targetFrame?.isMainFrame == true,
            navigationAction.navigationType != .backForward,
            navigationAction.navigationType != .reload,
            (request.httpMethod ?? "GET") == "GET",
            request.httpBody == nil,
            let url = request.url,
            Self.isWebURL(url),
            request.value(forHTTPHeaderField: "Accept-Language") != JapaneseWebSupport.acceptLanguage,
            !Self.isSameDocument(url, as: webView.url)
        else {
            return .allow
        }

        webView.load(JapaneseWebSupport.localized(request))
        return .cancel
    }
}

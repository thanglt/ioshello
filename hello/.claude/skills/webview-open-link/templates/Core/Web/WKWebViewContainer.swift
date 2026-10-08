//
//  WKWebViewContainer.swift
//  hello
//

import SwiftUI
import WebKit

/// Hosts a `WKWebView` owned by a view model, so its state survives SwiftUI updates.
struct WKWebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

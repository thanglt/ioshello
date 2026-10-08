//
//  InAppWebView.swift
//  hello
//

import SwiftUI

/// Shows a page in a `WKWebView` without the app's navigation bar; the page has its own
/// header, and its back button closes this screen.
struct InAppWebView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: InAppWebViewModel

    init(request: URLRequest, userAgentPrefix: String) {
        _viewModel = State(
            initialValue: InAppWebViewModel(request: request, userAgentPrefix: userAgentPrefix)
        )
    }

    var body: some View {
        WKWebViewContainer(webView: viewModel.webView)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) {
                if viewModel.isLoading {
                    ProgressView(value: viewModel.estimatedProgress)
                        .progressViewStyle(.linear)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: viewModel.isCloseRequested) { _, isCloseRequested in
                if isCloseRequested {
                    dismiss()
                }
            }
            .task {
                await viewModel.loadIfNeeded()
            }
    }
}

#Preview {
    let viewModel = OrderHistoryViewModel()
    if let request = viewModel.request {
        NavigationStack {
            InAppWebView(request: request, userAgentPrefix: viewModel.userAgentPrefix)
        }
    }
}

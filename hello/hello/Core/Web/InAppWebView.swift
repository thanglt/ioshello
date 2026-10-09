//
//  InAppWebView.swift
//  hello
//

import SwiftUI

/// Shows a page in a `WKWebView` without the app's navigation bar; the page has its own
/// header, and its back button closes this screen.
/// Until the first page finishes loading, or when it fails, a Close button is shown so the
/// user is never stuck on a blank screen.
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
            .overlay {
                if viewModel.loadError != nil {
                    LoadFailedView(onRetry: viewModel.retry)
                }
            }
            .overlay(alignment: .top) {
                if viewModel.isLoading {
                    ProgressView(value: viewModel.estimatedProgress)
                        .progressViewStyle(.linear)
                }
            }
            .overlay(alignment: .topLeading) {
                if !viewModel.hasFinishedFirstLoad || viewModel.loadError != nil {
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .padding()
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

private struct LoadFailedView: View {
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Could not load the page", systemImage: "wifi.exclamationmark")
        } description: {
            Text("Check your connection and try again.")
        } actions: {
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .background(.background)
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

#Preview("Load failed") {
    LoadFailedView(onRetry: {})
}

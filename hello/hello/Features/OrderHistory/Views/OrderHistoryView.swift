//
//  OrderHistoryView.swift
//  hello
//

import SwiftUI

struct OrderHistoryView: View {
    @State private var viewModel: OrderHistoryViewModel

    init(viewModel: OrderHistoryViewModel = OrderHistoryViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Button("Open", action: viewModel.openTapped)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canOpen)
            }
            .navigationTitle("Order History")
            .navigationDestination(isPresented: $viewModel.isShowingWebView) {
                if let request = viewModel.request {
                    InAppWebView(request: request, userAgentPrefix: viewModel.userAgentPrefix)
                }
            }
        }
    }
}

#Preview {
    OrderHistoryView()
}

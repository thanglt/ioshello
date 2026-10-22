//
//  SavedLinksView.swift
//  hello
//

import SwiftUI

/// Main screen: add, edit and delete URLs, open one in the web view, or inspect its
/// query parameters.
struct SavedLinksView: View {
    @State private var viewModel: SavedLinksViewModel

    init(viewModel: SavedLinksViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            SavedLinksList(viewModel: viewModel)
                .navigationTitle("Saved URLs")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add URL", systemImage: "plus", action: viewModel.addTapped)
                    }
                }
                // No app navigation bar: the page has its own header, and its back button
                // posts `{"command":"back"}`, which closes the web view.
                .navigationDestination(item: $viewModel.linkInWebView) { link in
                    if let request = viewModel.request(for: link) {
                        InAppWebView(request: request, userAgentPrefix: viewModel.userAgentPrefix)
                    }
                }
                .sheet(item: $viewModel.editor) { editor in
                    SavedLinkEditorView(viewModel: viewModel, editor: editor)
                }
                .sheet(item: $viewModel.linkForParameters) { link in
                    SavedLinkParametersView(link: link)
                }
                .alert("Error", isPresented: isShowingError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
                .task {
                    viewModel.load()
                }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct SavedLinksList: View {
    let viewModel: SavedLinksViewModel

    var body: some View {
        List {
            ForEach(viewModel.links) { link in
                SavedLinkRow(
                    link: link,
                    onOpen: { viewModel.open(link) },
                    onShowParameters: { viewModel.showParameters(link) }
                )
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        viewModel.delete(link)
                    }
                    Button("Edit", systemImage: "pencil") {
                        viewModel.editTapped(link)
                    }
                    .tint(.orange)
                }
                .contextMenu {
                    Button("Edit", systemImage: "pencil") { viewModel.editTapped(link) }
                    Button("Delete", systemImage: "trash", role: .destructive) { viewModel.delete(link) }
                }
            }
        }
        .overlay {
            if viewModel.links.isEmpty {
                ContentUnavailableView(
                    "No URLs",
                    systemImage: "link",
                    description: Text("Tap + to add a URL.")
                )
            }
        }
    }
}

private struct SavedLinkRow: View {
    let link: SavedLink
    let onOpen: () -> Void
    let onShowParameters: () -> Void

    var body: some View {
        HStack {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.displayTitle)
                        .font(.headline)
                    Text(link.urlString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens the URL"))

            Button("Show URL parameters", systemImage: "info.circle", action: onShowParameters)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .imageScale(.large)
        }
    }
}

#Preview {
    SavedLinksView(viewModel: SavedLinksViewModel(store: InMemorySavedLinkStore(links: [
        SavedLink(urlString: "https://www.apple.com/search?q=iphone&page=2"),
        SavedLink(urlString: "https://example.com"),
    ])))
}

#Preview("Empty") {
    SavedLinksView(viewModel: SavedLinksViewModel(store: InMemorySavedLinkStore()))
}

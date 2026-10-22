//
//  SavedLinkParametersView.swift
//  hello
//

import SwiftUI

/// Sheet listing a URL's parts and its query parameters (percent-decoded).
struct SavedLinkParametersView: View {
    @Environment(\.dismiss) private var dismiss
    let link: SavedLink

    var body: some View {
        NavigationStack {
            List {
                Section("URL") {
                    Text(link.urlString)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }
                URLComponentsSection(components: link.components)
                QueryParametersSection(items: link.queryItems)
            }
            .navigationTitle("URL Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct URLComponentsSection: View {
    let components: URLComponents?

    var body: some View {
        Section("Components") {
            row("Scheme", components?.scheme)
            // `host` is nil for hosts that fail IDNA decoding; show the raw host then.
            row("Host", components?.host ?? components?.encodedHost)
            row("Port", components?.port.map(String.init))
            row("Path", components?.path)
            row("Fragment", components?.fragment)
        }
    }

    @ViewBuilder
    private func row(_ title: LocalizedStringKey, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            LabeledContent(title) {
                Text(value)
                    .textSelection(.enabled)
            }
        }
    }
}

private struct QueryParametersSection: View {
    let items: [URLQueryItem]

    var body: some View {
        Section {
            if items.isEmpty {
                Text("No query parameters")
                    .foregroundStyle(.secondary)
            } else {
                // Names can repeat (`a=1&a=2`), so rows are identified by position.
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline.bold())
                        Text(item.value ?? "")
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .textSelection(.enabled)
                }
            }
        } header: {
            HStack {
                Text("Query Parameters")
                Spacer()
                Text(items.count, format: .number)
            }
        }
    }
}

#Preview {
    SavedLinkParametersView(
        link: SavedLink(urlString: "https://example.com:8080/search?q=swift%20ui&page=2&lang=vi#top")
    )
}

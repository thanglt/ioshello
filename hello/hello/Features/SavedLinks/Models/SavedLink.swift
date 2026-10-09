//
//  SavedLink.swift
//  hello
//

import Foundation

/// A URL the user saved on the main screen.
struct SavedLink: Identifiable, Hashable, Sendable {
    let id: UUID
    var urlString: String
    var createdAt: Date

    init(id: UUID = UUID(), urlString: String, createdAt: Date = .now) {
        self.id = id
        self.urlString = urlString
        self.createdAt = createdAt
    }

    var url: URL? { URL(string: urlString) }

    var components: URLComponents? { URLComponents(string: urlString) }

    /// Percent-decoded `name=value` pairs, in the order they appear in the URL. Skips the
    /// empty item a trailing `&` produces.
    var queryItems: [URLQueryItem] {
        (components?.queryItems ?? []).filter { !$0.name.isEmpty || $0.value != nil }
    }

    /// The host, or the whole string when it has none.
    var displayTitle: String { url?.host() ?? urlString }

    /// Trims the input, adds `https://` when no scheme is given, and accepts only
    /// http(s) URLs that have a host.
    static func normalizedURLString(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard
            let url = URL(string: candidate),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = url.host(), !host.isEmpty
        else {
            return nil
        }
        return url.absoluteString
    }
}

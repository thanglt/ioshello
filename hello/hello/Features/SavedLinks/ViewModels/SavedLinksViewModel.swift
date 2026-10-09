//
//  SavedLinksViewModel.swift
//  hello
//

import Foundation
import Observation

@Observable
final class SavedLinksViewModel {
    /// The add/edit sheet.
    enum Editor: Identifiable, Hashable {
        case add
        case edit(SavedLink)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let link): link.id.uuidString
            }
        }
    }

    private(set) var links: [SavedLink] = []
    var editor: Editor?
    var draftURL = ""
    private(set) var draftError: String?
    /// Pushes the web view.
    var linkInWebView: SavedLink?
    /// Shows the URL parameters sheet.
    var linkForParameters: SavedLink?
    var errorMessage: String?

    /// Each one is added to the list once, the next time the list loads, so URLs added here
    /// later also reach existing installs. Deleting one keeps it deleted.
    static let defaultURLStrings = [
        "https://active.amanotesunny.com/customer/views/shopping/default/order-history?mode=orderHistory&shoppingMode=TAKE_OUT&accountId=df428e06-1a77-4e1d-9bff-7428958c00f8&retailerId=91a74429-bce0-4211-96c7-4bc2dd8ff5ec&_top=1",
        "https://sunnypoint-vn.sunnypoint.jp/customer/views/shopping/default/order-history?mode=orderHistory&shoppingMode=TAKE_OUT&accountId=679d2587-6d38-4926-a941-5c94d34ca662&retailerId=91a74429-bce0-4211-96c7-4bc2dd8ff5ec&_top=1",
    ]
    /// The default URLs already added.
    static let addedDefaultsKey = "SavedLinks.addedDefaultURLs"
    /// Set by an earlier build that added only the first default URL.
    static let legacyDidAddDefaultsKey = "SavedLinks.didAddDefaultLinks"

    let userAgentPrefix: String
    @ObservationIgnored private let store: any SavedLinkStore
    @ObservationIgnored private let defaults: UserDefaults

    init(store: any SavedLinkStore, bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        self.store = store
        self.defaults = defaults
        self.userAgentPrefix = WebUserAgent.prefix(bundle: bundle)
    }

    func load() {
        do {
            try addDefaultLinksIfNeeded()
            links = try store.fetchAll()
        } catch {
            errorMessage = String(localized: "Could not load the saved URLs.")
        }
    }

    func addTapped() {
        draftURL = ""
        draftError = nil
        editor = .add
    }

    func editTapped(_ link: SavedLink) {
        draftURL = link.urlString
        draftError = nil
        editor = .edit(link)
    }

    func cancelEditing() {
        editor = nil
    }

    func saveDraft() {
        guard let editor else { return }
        guard let urlString = SavedLink.normalizedURLString(from: draftURL) else {
            draftError = String(localized: "Enter a valid http or https URL.")
            return
        }
        do {
            switch editor {
            case .add:
                try store.insert(SavedLink(urlString: urlString))
            case .edit(var link):
                link.urlString = urlString
                try store.update(link)
            }
            self.editor = nil
            load()
        } catch {
            draftError = String(localized: "Could not save the URL.")
        }
    }

    func delete(_ link: SavedLink) {
        delete(ids: [link.id])
    }

    func delete(at offsets: IndexSet) {
        delete(ids: offsets.map { links[$0].id })
    }

    func open(_ link: SavedLink) {
        linkInWebView = link
    }

    func showParameters(_ link: SavedLink) {
        linkForParameters = link
    }

    func request(for link: SavedLink) -> URLRequest? {
        link.url.map { URLRequest(url: $0) }
    }

    private func addDefaultLinksIfNeeded() throws {
        var added = Set(defaults.stringArray(forKey: Self.addedDefaultsKey) ?? [])
        if defaults.bool(forKey: Self.legacyDidAddDefaultsKey), let first = Self.defaultURLStrings.first {
            added.insert(first)
        }
        let pending = Self.defaultURLStrings.filter { !added.contains($0) }
        guard !pending.isEmpty else { return }

        let existing = Set(try store.fetchAll().map(\.urlString))
        // Insert in reverse with increasing dates so the list (newest first) keeps this order.
        let now = Date.now
        for (offset, urlString) in pending.reversed().enumerated() where !existing.contains(urlString) {
            try store.insert(SavedLink(urlString: urlString, createdAt: now.addingTimeInterval(Double(offset))))
        }
        added.formUnion(pending)
        defaults.set(Array(added).sorted(), forKey: Self.addedDefaultsKey)
        defaults.removeObject(forKey: Self.legacyDidAddDefaultsKey)
    }

    private func delete(ids: [UUID]) {
        do {
            try store.delete(ids: ids)
        } catch {
            errorMessage = String(localized: "Could not delete the URL.")
        }
        load()
    }
}

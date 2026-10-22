//
//  SavedLinkStore.swift
//  hello
//

import CoreData
import Foundation

/// Keeps saved links between launches.
protocol SavedLinkStore {
    /// Newest first.
    func fetchAll() throws -> [SavedLink]
    func insert(_ link: SavedLink) throws
    func update(_ link: SavedLink) throws
    func delete(ids: [UUID]) throws
}

/// Stores links as `SavedLinkEntity` rows in the app's Core Data store.
/// Uses the view context, so it stays on the main actor.
struct CoreDataSavedLinkStore: SavedLinkStore {
    let context: NSManagedObjectContext

    func fetchAll() throws -> [SavedLink] {
        let request = NSFetchRequest<SavedLinkEntity>(entityName: "SavedLinkEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLinkEntity.createdAt, ascending: false)]
        return try context.fetch(request).compactMap { entity in
            guard let id = entity.id, let urlString = entity.urlString else { return nil }
            return SavedLink(id: id, urlString: urlString, createdAt: entity.createdAt ?? .distantPast)
        }
    }

    func insert(_ link: SavedLink) throws {
        let entity = SavedLinkEntity(context: context)
        entity.id = link.id
        entity.urlString = link.urlString
        entity.createdAt = link.createdAt
        try saveChanges()
    }

    func update(_ link: SavedLink) throws {
        for entity in try entities(ids: [link.id]) {
            entity.urlString = link.urlString
        }
        try saveChanges()
    }

    func delete(ids: [UUID]) throws {
        for entity in try entities(ids: ids) {
            context.delete(entity)
        }
        try saveChanges()
    }

    private func entities(ids: [UUID]) throws -> [SavedLinkEntity] {
        let request = NSFetchRequest<SavedLinkEntity>(entityName: "SavedLinkEntity")
        request.predicate = NSPredicate(format: "id IN %@", ids)
        return try context.fetch(request)
    }

    private func saveChanges() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

/// Keeps links in memory, for previews and tests.
final class InMemorySavedLinkStore: SavedLinkStore {
    private var links: [SavedLink]

    init(links: [SavedLink] = []) {
        self.links = links
    }

    func fetchAll() throws -> [SavedLink] {
        links.sorted { $0.createdAt > $1.createdAt }
    }

    func insert(_ link: SavedLink) throws {
        links.append(link)
    }

    func update(_ link: SavedLink) throws {
        guard let index = links.firstIndex(where: { $0.id == link.id }) else { return }
        links[index] = link
    }

    func delete(ids: [UUID]) throws {
        links.removeAll { ids.contains($0.id) }
    }
}

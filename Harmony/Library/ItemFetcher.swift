//
//  SongsFetcher.swift
//  Harmony
//
//  Created by Claudio Cambra on 11/5/25.
//

import HarmonyKit
import SwiftData
import SwiftUI

class ItemFetcher<T> where T: PersistentModel {
    @ModelActor
    actor BackgroundActor {
        func fetchItems(
            predicate: Predicate<T>?, sortDescriptors: [SortDescriptor<T>]
        ) throws -> Set<PersistentIdentifier> {
            let backgroundContext = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortDescriptors)
            let items = try backgroundContext.fetch(descriptor)
            return Set(items.map { $0.persistentModelID })
        }
    }

    private let modelContainer: ModelContainer
    private lazy var backgroundActor = BackgroundActor(modelContainer: modelContainer)

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func getItems(
        predicate: Predicate<T>? = nil, sortDescriptors: [SortDescriptor<T>] = []
    ) async throws -> Set<PersistentIdentifier> {
        try await backgroundActor.fetchItems(predicate: predicate, sortDescriptors: sortDescriptors)
    }
}

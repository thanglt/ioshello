//
//  helloApp.swift
//  hello
//
//  Created by Le Thang on 8/10/26.
//

import SwiftUI
import CoreData

@main
struct helloApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            OrderHistoryView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

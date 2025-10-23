//
//  CoreDataManager.swift
//  Toolbox
//
//  Core Data stack and migration manager
//

import Foundation
import CoreData
import UIKit

// MARK: - Core Data Manager
class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {
        // Private init to ensure singleton
    }

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ToolboxDataModel")

        // Configure persistent store options
        let description = container.persistentStoreDescriptions.first
        description?.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle error appropriately in production
                print("❌ CoreDataManager: Unresolved error loading persistent stores: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("✅ CoreDataManager: Persistent store loaded successfully")
                print("   Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
            }
        }

        // Configure merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Saving Support

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ CoreDataManager: Context saved successfully")
            } catch {
                let nserror = error as NSError
                print("❌ CoreDataManager: Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Background Context

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Data Migration from UserDefaults

    func migrateDataFromUserDefaults() {
        print("🔄 CoreDataManager: Starting data migration from UserDefaults...")

        // Check if migration has already been completed
        if UserDefaults.standard.bool(forKey: "CoreDataMigrationCompleted") {
            print("✅ CoreDataManager: Migration already completed, skipping")
            return
        }

        var migrationErrors: [String] = []

        // Migrate Notes
        do {
            try migrateNotes()
            print("✅ CoreDataManager: Notes migrated successfully")
        } catch {
            let errorMsg = "Failed to migrate notes: \(error.localizedDescription)"
            print("❌ CoreDataManager: \(errorMsg)")
            migrationErrors.append(errorMsg)
        }

        // Migrate Tasks
        do {
            try migrateTasks()
            print("✅ CoreDataManager: Tasks migrated successfully")
        } catch {
            let errorMsg = "Failed to migrate tasks: \(error.localizedDescription)"
            print("❌ CoreDataManager: \(errorMsg)")
            migrationErrors.append(errorMsg)
        }

        // Migrate Vault Items
        do {
            try migrateVaultItems()
            print("✅ CoreDataManager: Vault items migrated successfully")
        } catch {
            let errorMsg = "Failed to migrate vault items: \(error.localizedDescription)"
            print("❌ CoreDataManager: \(errorMsg)")
            migrationErrors.append(errorMsg)
        }

        // Mark migration as complete if no errors
        if migrationErrors.isEmpty {
            UserDefaults.standard.set(true, forKey: "CoreDataMigrationCompleted")
            print("✅ CoreDataManager: All data migrated successfully")
        } else {
            print("⚠️ CoreDataManager: Migration completed with errors:")
            migrationErrors.forEach { print("   - \($0)") }
        }
    }

    // MARK: - Private Migration Methods

    private func migrateNotes() throws {
        let notesKey = "saved_notes"

        guard let data = UserDefaults.standard.data(forKey: notesKey) else {
            print("ℹ️ CoreDataManager: No notes data found in UserDefaults")
            return
        }

        struct OldNote: Codable {
            var id: UUID
            var title: String
            var content: String
            var createdAt: Date
        }

        let decoder = JSONDecoder()
        let oldNotes = try decoder.decode([OldNote].self, from: data)

        print("📝 CoreDataManager: Migrating \(oldNotes.count) notes...")

        let context = viewContext
        for oldNote in oldNotes {
            let note = NoteEntity(context: context)
            note.id = oldNote.id
            note.title = oldNote.title
            note.content = oldNote.content
            note.createdAt = oldNote.createdAt
        }

        try context.save()
        print("✅ CoreDataManager: \(oldNotes.count) notes migrated")
    }

    private func migrateTasks() throws {
        let tasksKey = "saved_tasks"

        guard let data = UserDefaults.standard.data(forKey: tasksKey) else {
            print("ℹ️ CoreDataManager: No tasks data found in UserDefaults")
            return
        }

        struct OldTask: Codable {
            var id: UUID
            var title: String
            var isCompleted: Bool
            var createdAt: Date
            var dueDate: Date?
            var category: String?
            var priority: Int
            var notes: String?
            var hasReminder: Bool
            var reminderTime: Date?
        }

        let decoder = JSONDecoder()
        let oldTasks = try decoder.decode([OldTask].self, from: data)

        print("✅ CoreDataManager: Migrating \(oldTasks.count) tasks...")

        let context = viewContext
        for oldTask in oldTasks {
            let task = TaskEntity(context: context)
            task.id = oldTask.id
            task.title = oldTask.title
            task.isCompleted = oldTask.isCompleted
            task.createdAt = oldTask.createdAt
            task.dueDate = oldTask.dueDate
            task.category = oldTask.category
            task.priority = Int16(oldTask.priority)
            task.notes = oldTask.notes
            task.hasReminder = oldTask.hasReminder
            task.reminderTime = oldTask.reminderTime
        }

        try context.save()
        print("✅ CoreDataManager: \(oldTasks.count) tasks migrated")
    }

    private func migrateVaultItems() throws {
        let itemsKey = "vault_items"

        guard let data = UserDefaults.standard.data(forKey: itemsKey) else {
            print("ℹ️ CoreDataManager: No vault items data found in UserDefaults")
            return
        }

        struct OldVaultItem: Codable {
            var id: UUID
            var title: String
            var category: String
            var imageName: String
            var thumbnailName: String?
            var createdAt: Date
            var tags: [String]
            var notes: String?
            var extractedText: String?
        }

        let decoder = JSONDecoder()
        let oldItems = try decoder.decode([OldVaultItem].self, from: data)

        print("🔒 CoreDataManager: Migrating \(oldItems.count) vault items...")

        let context = viewContext
        for oldItem in oldItems {
            let item = VaultItemEntity(context: context)
            item.id = oldItem.id
            item.title = oldItem.title
            item.category = oldItem.category
            item.imageName = oldItem.imageName
            item.thumbnailName = oldItem.thumbnailName
            item.createdAt = oldItem.createdAt
            item.tags = oldItem.tags
            item.notes = oldItem.notes
            item.extractedText = oldItem.extractedText
        }

        try context.save()
        print("✅ CoreDataManager: \(oldItems.count) vault items migrated")
    }

    // MARK: - Utility Methods

    func deleteAllData() {
        let entities = persistentContainer.managedObjectModel.entities

        for entity in entities {
            guard let entityName = entity.name else { continue }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try viewContext.execute(deleteRequest)
                print("✅ CoreDataManager: Deleted all data from \(entityName)")
            } catch {
                print("❌ CoreDataManager: Failed to delete \(entityName): \(error)")
            }
        }

        saveContext()
    }
}

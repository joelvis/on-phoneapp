//
//  CoreDataExtensions.swift
//  On phoneapp
//
//  Extensions for Core Data entities
//

import Foundation
import CoreData

// MARK: - VaultItemEntity Extension
extension VaultItemEntity {
    // Computed property for tags (converts between [String] and Data)
    public var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Convert to struct for UI
    func toVaultItem() -> VaultItem {
        // Parse documentType from string, default to .image if invalid or nil
        let docType: DocumentType
        if let typeString = self.documentType {
            docType = DocumentType(rawValue: typeString) ?? .image
        } else {
            docType = .image
        }

        return VaultItem(
            id: self.id!,
            title: self.title!,
            category: self.category!,
            imageName: self.imageName!,
            thumbnailName: self.thumbnailName,
            createdAt: self.createdAt!,
            tags: self.tags,
            notes: self.notes,
            extractedText: self.extractedText,
            documentType: docType
        )
    }

    // Create from struct
    static func from(item: VaultItem, context: NSManagedObjectContext) -> VaultItemEntity {
        let entity = VaultItemEntity(context: context)
        entity.id = item.id
        entity.title = item.title
        entity.category = item.category
        entity.imageName = item.imageName
        entity.thumbnailName = item.thumbnailName
        entity.createdAt = item.createdAt
        entity.tags = item.tags
        entity.notes = item.notes
        entity.extractedText = item.extractedText
        entity.documentType = item.documentType.rawValue
        return entity
    }

    // Update from struct
    func update(from item: VaultItem) {
        self.title = item.title
        self.category = item.category
        self.thumbnailName = item.thumbnailName
        self.tags = item.tags
        self.notes = item.notes
        self.extractedText = item.extractedText
        self.documentType = item.documentType.rawValue
    }
}

// MARK: - NoteEntity Extension
extension NoteEntity {
    // Convert to struct for UI
    func toNote() -> Note {
        return Note(
            id: self.id!,
            title: self.title!,
            content: self.content!,
            createdAt: self.createdAt!
        )
    }
    
    // Create from struct
    static func from(note: Note, context: NSManagedObjectContext) -> NoteEntity {
        let entity = NoteEntity(context: context)
        entity.id = note.id
        entity.title = note.title
        entity.content = note.content
        entity.createdAt = note.createdAt
        return entity
    }
}

// MARK: - TaskEntity Extension
extension TaskEntity {
    // Convert to struct for UI
    func toTask() -> Task {
        return Task(
            id: self.id!,
            title: self.title!,
            isCompleted: self.isCompleted,
            createdAt: self.createdAt!,
            dueDate: self.dueDate,
            category: self.category,
            priority: Int(self.priority),
            notes: self.notes,
            hasReminder: self.hasReminder,
            reminderTime: self.reminderTime
        )
    }
    
    // Create from struct
    static func from(task: Task, context: NSManagedObjectContext) -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.id = task.id
        entity.title = task.title
        entity.isCompleted = task.isCompleted
        entity.createdAt = task.createdAt
        entity.dueDate = task.dueDate
        entity.category = task.category
        entity.priority = Int16(task.priority)
        entity.notes = task.notes
        entity.hasReminder = task.hasReminder
        entity.reminderTime = task.reminderTime
        return entity
    }
    
    // Update from struct
    func update(from task: Task) {
        self.title = task.title
        self.isCompleted = task.isCompleted
        self.dueDate = task.dueDate
        self.category = task.category
        self.priority = Int16(task.priority)
        self.notes = task.notes
        self.hasReminder = task.hasReminder
        self.reminderTime = task.reminderTime
    }
}


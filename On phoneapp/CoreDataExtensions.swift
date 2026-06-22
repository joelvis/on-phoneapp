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
    
    // Convert to struct for UI.
    // Returns nil (instead of crashing) if a row is missing required fields —
    // e.g. a partially-written or migrated row. Callers should use compactMap.
    func toVaultItem() -> VaultItem? {
        guard let id = self.id,
              let title = self.title,
              let category = self.category,
              let imageName = self.imageName,
              let createdAt = self.createdAt else {
            print("⚠️ VaultItemEntity.toVaultItem(): skipping row with missing required fields")
            return nil
        }

        // Parse documentType from string, default to .image if invalid or nil
        let docType = DocumentType(rawValue: self.documentType ?? "") ?? .image

        return VaultItem(
            id: id,
            title: title,
            category: category,
            imageName: imageName,
            thumbnailName: self.thumbnailName,
            createdAt: createdAt,
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
    // JSON-bridged computed properties for the new Binary attributes
    public var reminderOffsets: [Int] {
        get {
            guard let data = reminderOffsetsData else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        }
        set { reminderOffsetsData = try? JSONEncoder().encode(newValue) }
    }

    public var notificationIdentifiers: [String] {
        get {
            guard let data = notificationIdsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set { notificationIdsData = try? JSONEncoder().encode(newValue) }
    }

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
            reminderTime: self.reminderTime,
            startDate: self.startDate,
            endDate: self.endDate,
            isAllDay: self.isAllDay,
            recurrenceRule: self.recurrenceRule,
            reminderOffsets: self.reminderOffsets,
            calendarEventID: self.calendarEventID,
            notificationIdentifiers: self.notificationIdentifiers,
            textMe: self.textMe,
            updatedAt: self.updatedAt
        )
    }

    // Create from struct — sets identity + creation date, then delegates the rest
    // to update(from:) so the two paths can never drift out of sync.
    static func from(task: Task, context: NSManagedObjectContext) -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.id = task.id
        entity.createdAt = task.createdAt
        entity.update(from: task)
        return entity
    }

    // Update from struct (everything except identity + creation date)
    func update(from task: Task) {
        self.title = task.title
        self.isCompleted = task.isCompleted
        self.dueDate = task.dueDate
        self.category = task.category
        self.priority = Int16(task.priority)
        self.notes = task.notes
        self.hasReminder = task.hasReminder
        self.reminderTime = task.reminderTime
        self.startDate = task.startDate
        self.endDate = task.endDate
        self.isAllDay = task.isAllDay
        self.recurrenceRule = task.recurrenceRule
        self.reminderOffsets = task.reminderOffsets
        self.calendarEventID = task.calendarEventID
        self.notificationIdentifiers = task.notificationIdentifiers
        self.textMe = task.textMe
        self.updatedAt = Date()
    }
}


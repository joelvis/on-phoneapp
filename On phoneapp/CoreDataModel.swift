//
//  CoreDataModel.swift
//  On phoneapp
//
//  Programmatic Core Data model setup
//
//  IMPORTANT: You need to create a .xcdatamodeld file in Xcode
//  Instructions are provided below
//

import Foundation
import CoreData

/*
 ================================================================================
 XCODE CORE DATA MODEL SETUP INSTRUCTIONS
 ================================================================================

 1. In Xcode, go to File > New > File
 2. Select "Data Model" under Core Data section
 3. Name it "ToolboxDataModel" (must match the name in CoreDataManager)
 4. Click Create

 5. Create the following entities:

 ┌─────────────────────────────────────────────────────────────────────────┐
 │ ENTITY: NoteEntity                                                       │
 ├─────────────────────────────────────────────────────────────────────────┤
 │ Attributes:                                                              │
 │   - id         : UUID       (required)                                   │
 │   - title      : String     (required)                                   │
 │   - content    : String     (required)                                   │
 │   - createdAt  : Date       (required)                                   │
 ├─────────────────────────────────────────────────────────────────────────┤
 │ Indexes:                                                                 │
 │   - title (for search optimization)                                      │
 │   - createdAt (for sorting)                                              │
 └─────────────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────────────┐
 │ ENTITY: TaskEntity                                                       │
 ├─────────────────────────────────────────────────────────────────────────┤
 │ Attributes:                                                              │
 │   - id           : UUID       (required)                                 │
 │   - title        : String     (required)                                 │
 │   - isCompleted  : Boolean    (required, default: false)                 │
 │   - createdAt    : Date       (required)                                 │
 │   - dueDate      : Date       (optional)                                 │
 │   - category     : String     (optional)                                 │
 │   - priority     : Integer16  (required, default: 1)                     │
 │   - notes        : String     (optional)                                 │
 │   - hasReminder  : Boolean    (required, default: false)                 │
 │   - reminderTime : Date       (optional)                                 │
 ├─────────────────────────────────────────────────────────────────────────┤
 │ Indexes:                                                                 │
 │   - title (for search optimization)                                      │
 │   - category (for filtering)                                             │
 │   - dueDate (for sorting)                                                │
 │   - priority (for sorting)                                               │
 └─────────────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────────────┐
 │ ENTITY: VaultItemEntity                                                  │
 ├─────────────────────────────────────────────────────────────────────────┤
 │ Attributes:                                                              │
 │   - id            : UUID       (required)                                │
 │   - title         : String     (required)                                │
 │   - category      : String     (required)                                │
 │   - imageName     : String     (required) - encrypted file path          │
 │   - thumbnailName : String     (optional)                                │
 │   - createdAt     : Date       (required)                                │
 │   - tagsData      : Binary     (optional) - JSON encoded [String]        │
 │   - notes         : String     (optional)                                │
 │   - extractedText : String     (optional) - OCR text for search          │
 │   - documentType  : String     (required, default: "image") - pdf/image  │
 ├─────────────────────────────────────────────────────────────────────────┤
 │ Indexes:                                                                 │
 │   - title (for search optimization)                                      │
 │   - category (for filtering)                                             │
 │   - extractedText (for search optimization)                              │
 │   - createdAt (for sorting)                                              │
 └─────────────────────────────────────────────────────────────────────────┘

 6. For each entity, set the "Class" property:
    - NoteEntity: Module = "On_phoneapp", Class = "NoteEntity"
    - TaskEntity: Module = "On_phoneapp", Class = "TaskEntity"
    - VaultItemEntity: Module = "On_phoneapp", Class = "VaultItemEntity"

 7. Set "Codegen" to "Manual/None" for all entities (we have custom classes)

 8. Add indexes by selecting the entity, clicking the "+" button in the
    Indexes section, and adding the attributes mentioned above

 ================================================================================
*/

// MARK: - Programmatic Model Builder (Backup/Reference)
class CoreDataModelBuilder {

    /// Creates the Core Data model programmatically
    /// This is a backup method in case the .xcdatamodeld file is not available
    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create entities
        let noteEntity = createNoteEntity()
        let taskEntity = createTaskEntity()
        let vaultItemEntity = createVaultItemEntity()

        model.entities = [noteEntity, taskEntity, vaultItemEntity]

        return model
    }

    // MARK: - Entity Creation

    private static func createNoteEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "NoteEntity"
        entity.managedObjectClassName = "NoteEntity"

        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false

        let contentAttr = NSAttributeDescription()
        contentAttr.name = "content"
        contentAttr.attributeType = .stringAttributeType
        contentAttr.isOptional = false

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false

        entity.properties = [idAttr, titleAttr, contentAttr, createdAtAttr]

        return entity
    }

    private static func createTaskEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TaskEntity"
        entity.managedObjectClassName = "TaskEntity"

        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false

        let isCompletedAttr = NSAttributeDescription()
        isCompletedAttr.name = "isCompleted"
        isCompletedAttr.attributeType = .booleanAttributeType
        isCompletedAttr.isOptional = false
        isCompletedAttr.defaultValue = false

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false

        let dueDateAttr = NSAttributeDescription()
        dueDateAttr.name = "dueDate"
        dueDateAttr.attributeType = .dateAttributeType
        dueDateAttr.isOptional = true

        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isOptional = true

        let priorityAttr = NSAttributeDescription()
        priorityAttr.name = "priority"
        priorityAttr.attributeType = .integer16AttributeType
        priorityAttr.isOptional = false
        priorityAttr.defaultValue = 1

        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true

        let hasReminderAttr = NSAttributeDescription()
        hasReminderAttr.name = "hasReminder"
        hasReminderAttr.attributeType = .booleanAttributeType
        hasReminderAttr.isOptional = false
        hasReminderAttr.defaultValue = false

        let reminderTimeAttr = NSAttributeDescription()
        reminderTimeAttr.name = "reminderTime"
        reminderTimeAttr.attributeType = .dateAttributeType
        reminderTimeAttr.isOptional = true

        entity.properties = [
            idAttr, titleAttr, isCompletedAttr, createdAtAttr, dueDateAttr,
            categoryAttr, priorityAttr, notesAttr, hasReminderAttr, reminderTimeAttr
        ]

        return entity
    }

    private static func createVaultItemEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "VaultItemEntity"
        entity.managedObjectClassName = "VaultItemEntity"

        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false

        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isOptional = false

        let imageNameAttr = NSAttributeDescription()
        imageNameAttr.name = "imageName"
        imageNameAttr.attributeType = .stringAttributeType
        imageNameAttr.isOptional = false

        let thumbnailNameAttr = NSAttributeDescription()
        thumbnailNameAttr.name = "thumbnailName"
        thumbnailNameAttr.attributeType = .stringAttributeType
        thumbnailNameAttr.isOptional = true

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false

        let tagsDataAttr = NSAttributeDescription()
        tagsDataAttr.name = "tagsData"
        tagsDataAttr.attributeType = .binaryDataAttributeType
        tagsDataAttr.isOptional = true

        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true

        let extractedTextAttr = NSAttributeDescription()
        extractedTextAttr.name = "extractedText"
        extractedTextAttr.attributeType = .stringAttributeType
        extractedTextAttr.isOptional = true

        let documentTypeAttr = NSAttributeDescription()
        documentTypeAttr.name = "documentType"
        documentTypeAttr.attributeType = .stringAttributeType
        documentTypeAttr.isOptional = false
        documentTypeAttr.defaultValue = "image"

        entity.properties = [
            idAttr, titleAttr, categoryAttr, imageNameAttr, thumbnailNameAttr,
            createdAtAttr, tagsDataAttr, notesAttr, extractedTextAttr, documentTypeAttr
        ]

        return entity
    }
}

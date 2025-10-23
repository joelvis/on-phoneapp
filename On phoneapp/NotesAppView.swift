//
//  NotesAppView.swift
//  Toolbox
//
//  Created by Joel  on 10/18/25.
//

import SwiftUI

// MARK: - Note Model
struct Note: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, content: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Notes Storage Manager
class NotesStorageManager {
    private let notesKey = "saved_notes"

    func saveNotes(_ notes: [Note]) {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }

    func loadNotes() -> [Note] {
        guard let data = UserDefaults.standard.data(forKey: notesKey),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            return []
        }
        return notes
    }
}

// MARK: - Main Notes App View
struct NotesAppView: View {
    @State private var notes: [Note] = []
    @State private var showingAddNote = false
    @State private var selectedNote: Note?

    private let storageManager = NotesStorageManager()

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                if notes.isEmpty {
                    emptyStateView
                } else {
                    notesListView
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddNote = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(onSave: { note in
                    addNote(note)
                })
            }
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note, onDelete: {
                    deleteNote(note)
                    selectedNote = nil
                }, onUpdate: { updatedNote in
                    updateNote(updatedNote)
                })
            }
            .onAppear {
                loadNotes()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 80))
                .foregroundColor(.orange.opacity(0.5))

            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the pencil icon to create your first note")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Notes List
    private var notesListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(notes.sorted(by: { $0.createdAt > $1.createdAt })) { note in
                    NoteCardView(note: note)
                        .onTapGesture {
                            selectedNote = note
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Note Operations
    private func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }

    private func updateNote(_ updatedNote: Note) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            saveNotes()
        }
    }

    private func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }

    private func saveNotes() {
        storageManager.saveNotes(notes)
    }

    private func loadNotes() {
        notes = storageManager.loadNotes()
    }
}

// MARK: - Note Card View
struct NoteCardView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(note.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)

            // Content preview
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            // Date
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(note.createdAt, style: .date)
                    .font(.caption)
                Spacer()
                Image(systemName: "clock")
                    .font(.caption2)
                Text(note.createdAt, style: .time)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Add Note View
struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var noteTitle = ""
    @State private var noteContent = ""
    @FocusState private var isTitleFocused: Bool

    let onSave: (Note) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Title field
                    TextField("Title", text: $noteTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .focused($isTitleFocused)

                    Divider()

                    // Content field
                    TextEditor(text: $noteContent)
                        .font(.body)
                        .padding()
                        .scrollContentBackground(.hidden)
                        .background(Color(uiColor: .systemBackground))
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .fontWeight(.semibold)
                    .disabled(noteTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
    }

    private func saveNote() {
        let note = Note(
            title: noteTitle,
            content: noteContent
        )
        onSave(note)
        dismiss()
    }
}

// MARK: - Note Detail View
struct NoteDetailView: View {
    @Environment(\.dismiss) var dismiss
    let note: Note
    let onDelete: () -> Void
    let onUpdate: (Note) -> Void

    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                if isEditing {
                    // Edit mode
                    VStack(spacing: 0) {
                        // Title field
                        TextField("Title", text: $editedTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .focused($isTitleFocused)

                        Divider()

                        // Content field
                        TextEditor(text: $editedContent)
                            .font(.body)
                            .padding()
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .systemBackground))
                    }
                } else {
                    // View mode
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Title
                            Text(note.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .padding(.top)

                            // Date
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(note.createdAt, style: .date)
                                    .font(.caption)
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .padding(.leading, 8)
                                Text(note.createdAt, style: .time)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                            Divider()
                                .padding(.horizontal)

                            // Content
                            if !note.content.isEmpty {
                                Text(note.content)
                                    .font(.body)
                                    .padding(.horizontal)
                            } else {
                                Text("No content")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.horizontal)
                            }

                            Spacer()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            cancelEditing()
                        }
                        .foregroundColor(.secondary)
                    } else {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                        .disabled(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        HStack(spacing: 16) {
                            Button(action: {
                                startEditing()
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.orange)
                            }

                            Button(action: {
                                showingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this note? This action cannot be undone.")
            }
        }
    }

    // MARK: - Edit Functions
    private func startEditing() {
        editedTitle = note.title
        editedContent = note.content
        isEditing = true
        isTitleFocused = true
    }

    private func cancelEditing() {
        isEditing = false
        editedTitle = ""
        editedContent = ""
    }

    private func saveChanges() {
        let updatedNote = Note(
            id: note.id,
            title: editedTitle,
            content: editedContent,
            createdAt: note.createdAt
        )
        onUpdate(updatedNote)
        isEditing = false
    }
}

#Preview {
    NotesAppView()
}

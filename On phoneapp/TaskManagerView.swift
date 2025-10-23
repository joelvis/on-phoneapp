//
//  TaskManagerView.swift
//  Toolbox
//
//  Created by Joel  on 10/18/25.
//

import SwiftUI
import UserNotifications
import Combine

// MARK: - Task Model
struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    var category: String?
    var priority: Int // 0 = Low, 1 = Medium, 2 = High
    var notes: String?
    var hasReminder: Bool
    var reminderTime: Date?

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), dueDate: Date? = nil, category: String? = nil, priority: Int = 1, notes: String? = nil, hasReminder: Bool = false, reminderTime: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.category = category
        self.priority = priority
        self.notes = notes
        self.hasReminder = hasReminder
        self.reminderTime = reminderTime
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }

    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var priorityColor: Color {
        switch priority {
        case 2: return .red
        case 1: return .orange
        default: return .green
        }
    }

    var priorityText: String {
        switch priority {
        case 2: return "High"
        case 1: return "Medium"
        default: return "Low"
        }
    }
}

// MARK: - Task Storage Manager (Core Data)
class TaskStorageManager {
    private let context = CoreDataManager.shared.viewContext

    // Load all tasks from Core Data
    func loadTasks() -> [Task] {
        let fetchRequest: NSFetchRequest<TaskEntity> = NSFetchRequest(entityName: "TaskEntity")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "dueDate", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            let taskEntities = try context.fetch(fetchRequest)
            let tasks = taskEntities.map { $0.toTask() }
            print("✅ TaskStorageManager: Loaded \(tasks.count) tasks from Core Data")
            return tasks
        } catch {
            print("❌ TaskStorageManager: Failed to load tasks: \(error.localizedDescription)")
            return []
        }
    }

    // Save a single task to Core Data
    func saveTask(_ task: Task) {
        // Check if task already exists
        let fetchRequest: NSFetchRequest<TaskEntity> = NSFetchRequest(entityName: "TaskEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest)

            if let existingTask = results.first {
                // Update existing task
                existingTask.update(from: task)
                print("✅ TaskStorageManager: Updated task: \(task.title)")
            } else {
                // Create new task
                _ = TaskEntity.from(task: task, context: context)
                print("✅ TaskStorageManager: Created new task: \(task.title)")
            }

            try context.save()
        } catch {
            print("❌ TaskStorageManager: Failed to save task: \(error.localizedDescription)")
        }
    }

    // Delete a task from Core Data
    func deleteTask(_ task: Task) {
        let fetchRequest: NSFetchRequest<TaskEntity> = NSFetchRequest(entityName: "TaskEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest)
            if let taskEntity = results.first {
                context.delete(taskEntity)
                try context.save()
                print("✅ TaskStorageManager: Deleted task: \(task.title)")
            }
        } catch {
            print("❌ TaskStorageManager: Failed to delete task: \(error.localizedDescription)")
        }
    }

    // DEPRECATED: Kept for backwards compatibility during migration
    // This method is no longer used with Core Data
    func saveTasks(_ tasks: [Task]) {
        print("⚠️ TaskStorageManager: saveTasks(_:) is deprecated with Core Data")
        // Save each task individually
        for task in tasks {
            saveTask(task)
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isAuthorized = false

    private init() {
        checkAuthorizationStatus()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("❌ Authorization error: \(error)")
                } else if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("⚠️ Notification permission denied")
                }
                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleNotification(for task: Task) {
        guard task.hasReminder, let reminderTime = task.reminderTime else {
            print("❌ No reminder or reminder time for task: \(task.title)")
            return
        }

        // Cancel existing notification if any
        cancelNotification(for: task)

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.badge = 1

        // Add category info if available
        if let category = task.category {
            content.subtitle = category
        }

        // Calculate time interval from now
        let timeInterval = reminderTime.timeIntervalSinceNow

        print("⏰ Scheduling notification for: \(task.title)")
        print("   Current time: \(Date())")
        print("   Reminder time: \(reminderTime)")
        print("   Time interval: \(timeInterval) seconds (\(timeInterval/60) minutes)")

        // Check if reminder time is in the past (allow up to 5 seconds tolerance)
        if timeInterval < -5 {
            print("⚠️ Reminder time is in the past for task: \(task.title)")
            return
        }

        // Use time interval trigger for more reliable delivery
        // Ensure minimum interval of 1 second
        let adjustedInterval = max(1, timeInterval)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: adjustedInterval, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification scheduled successfully!")
                print("   Task: \(task.title)")
                print("   Will fire in: \(adjustedInterval) seconds")

                // Verify it was added
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("📋 Total pending notifications: \(requests.count)")
                    for req in requests {
                        if req.identifier == task.id.uuidString {
                            print("✓ Found our notification: \(req.content.body)")
                        }
                    }
                }
            }
        }
    }

    func cancelNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // Debug helper to check pending notifications
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Pending notifications: \(requests.count)")
            for request in requests {
                print("   - \(request.content.body) at \(String(describing: request.trigger))")
            }
            completion(requests)
        }
    }
}

// MARK: - Main Task Manager View
struct TaskManagerView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var selectedSegment = 0 // 0 = Today, 1 = Upcoming
    @State private var taskToEdit: Task?
    @StateObject private var notificationManager = NotificationManager.shared

    private let storageManager = TaskStorageManager()

    var filteredTasks: [Task] {
        let filtered: [Task]
        if selectedSegment == 0 {
            // Today: tasks due today or overdue
            filtered = tasks.filter { task in
                task.isOverdue || task.isDueToday || task.dueDate == nil
            }
        } else {
            // Upcoming: everything else
            filtered = tasks.filter { task in
                guard task.dueDate != nil else { return false }
                return !task.isDueToday && !task.isOverdue
            }
        }
        return filtered.sorted { task1, task2 in
            // Sort by priority first (high to low)
            if task1.priority != task2.priority {
                return task1.priority > task2.priority
            }
            // Then by due date (earliest first)
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            if task1.dueDate != nil { return true }
            if task2.dueDate != nil { return false }
            // Finally by creation date (newest first)
            return task1.createdAt > task2.createdAt
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background - light blue in light mode, dark in dark mode
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented control
                    if !tasks.isEmpty {
                        Picker("Filter", selection: $selectedSegment) {
                            Text("Today").tag(0)
                            Text("Upcoming").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }

                    // Task list
                    if tasks.isEmpty {
                        emptyStateView
                    } else if filteredTasks.isEmpty {
                        emptyFilteredStateView
                    } else {
                        taskListView
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        checkPendingNotifications()
                    }) {
                        Image(systemName: "bell.badge")
                            .font(.body)
                            .foregroundColor(.orange)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(onSave: { task in
                    addTask(task: task)
                })
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskView(existingTask: task, onSave: { updatedTask in
                    updateTask(updatedTask)
                })
            }
            .onAppear {
                loadTasks()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))

            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the + button to add your first task")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyFilteredStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedSegment == 0 ? "calendar.badge.clock" : "calendar")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))

            Text(selectedSegment == 0 ? "No Tasks for Today" : "No Upcoming Tasks")
                .font(.title2)
                .fontWeight(.semibold)

            Text(selectedSegment == 0 ? "You're all caught up!" : "Add a due date to see tasks here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Task List
    private var taskListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(filteredTasks) { task in
                    TaskRowView(
                        task: task,
                        onToggle: { toggleTaskCompletion(task) },
                        onDelete: { deleteTask(task) },
                        onEdit: { taskToEdit = task }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Task Operations (Core Data)
    private func addTask(task: Task) {
        tasks.insert(task, at: 0)
        storageManager.saveTask(task)

        // Schedule notification if reminder is enabled
        if task.hasReminder {
            scheduleNotificationIfAuthorized(for: task)
        }
    }

    private func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            let oldTask = tasks[index]
            tasks[index] = updatedTask
            storageManager.saveTask(updatedTask)

            // Update notification
            if updatedTask.hasReminder {
                scheduleNotificationIfAuthorized(for: updatedTask)
            } else if oldTask.hasReminder && !updatedTask.hasReminder {
                // Cancel notification if reminder was turned off
                notificationManager.cancelNotification(for: updatedTask)
            }
        }
    }

    private func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()

            // Cancel notification if task is completed
            if tasks[index].isCompleted {
                notificationManager.cancelNotification(for: task)
            }

            storageManager.saveTask(tasks[index])
        }
    }

    private func deleteTask(_ task: Task) {
        // Cancel notification
        notificationManager.cancelNotification(for: task)

        tasks.removeAll { $0.id == task.id }
        storageManager.deleteTask(task)
    }

    private func scheduleNotificationIfAuthorized(for task: Task) {
        if notificationManager.isAuthorized {
            notificationManager.scheduleNotification(for: task)
        } else {
            notificationManager.requestAuthorization { granted in
                if granted {
                    notificationManager.scheduleNotification(for: task)
                }
            }
        }
    }

    private func loadTasks() {
        tasks = storageManager.loadTasks()
    }

    private func checkPendingNotifications() {
        notificationManager.getPendingNotifications { requests in
            print("\n📋 === PENDING NOTIFICATIONS DEBUG ===")
            print("Total pending: \(requests.count)")
            for request in requests {
                print("---")
                print("ID: \(request.identifier)")
                print("Title: \(request.content.title)")
                print("Body: \(request.content.body)")
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    let fireDate = Date(timeIntervalSinceNow: trigger.timeInterval)
                    print("Will fire at: \(fireDate)")
                    print("In: \(trigger.timeInterval) seconds")
                }
                print("---")
            }
            print("=== END DEBUG ===\n")
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Completion button
                    Button(action: onToggle) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 28))
                            .foregroundColor(task.isCompleted ? .green : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Task content
                    VStack(alignment: .leading, spacing: 6) {
                        // Title and priority
                        HStack {
                            Text(task.title)
                                .font(.body)
                                .fontWeight(.medium)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(task.isCompleted ? .secondary : .primary)
                                .lineLimit(2)

                            Spacer()

                            // Priority badge
                            Text(task.priorityText)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(task.priorityColor)
                                .cornerRadius(8)
                        }

                        // Category
                        if let category = task.category, !category.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                    .font(.caption2)
                                Text(category)
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }

                        // Due date and reminder
                        HStack(spacing: 8) {
                            if let dueDate = task.dueDate {
                                HStack(spacing: 4) {
                                    Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                                        .font(.caption2)
                                    Text(dueDate, style: .date)
                                        .font(.caption)
                                }
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                            }

                            if task.hasReminder, let reminderTime = task.reminderTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "bell.fill")
                                        .font(.caption2)
                                    Text(reminderTime, style: .time)
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                            }
                        }

                        // Notes preview
                        if let notes = task.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .padding(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add/Edit Task View
struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @State private var taskTitle: String
    @State private var selectedPriority: Int
    @State private var category: String
    @State private var notes: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasReminder: Bool
    @State private var reminderTime: Date
    @FocusState private var isTextFieldFocused: Bool

    let existingTask: Task?
    let onSave: (Task) -> Void

    init(existingTask: Task? = nil, onSave: @escaping (Task) -> Void) {
        self.existingTask = existingTask
        self.onSave = onSave

        _taskTitle = State(initialValue: existingTask?.title ?? "")
        _selectedPriority = State(initialValue: existingTask?.priority ?? 1)
        _category = State(initialValue: existingTask?.category ?? "")
        _notes = State(initialValue: existingTask?.notes ?? "")
        _hasDueDate = State(initialValue: existingTask?.dueDate != nil)
        _dueDate = State(initialValue: existingTask?.dueDate ?? Date())
        _hasReminder = State(initialValue: existingTask?.hasReminder ?? false)
        _reminderTime = State(initialValue: existingTask?.reminderTime ?? Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Task Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            TextField("Enter task title", text: $taskTitle)
                                .padding()
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                                .font(.body)
                                .focused($isTextFieldFocused)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Picker("Priority", selection: $selectedPriority) {
                                Label("Low", systemImage: "flag.fill")
                                    .tag(0)
                                Label("Medium", systemImage: "flag.fill")
                                    .tag(1)
                                Label("High", systemImage: "flag.fill")
                                    .tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category (Optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            TextField("e.g., Work, Personal, Shopping", text: $category)
                                .padding()
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)

                        // Due Date
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasDueDate) {
                                Text("Set Due Date")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }

                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                                    .datePickerStyle(.graphical)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .onChange(of: hasDueDate) { _, newValue in
                            // If due date is turned off, also turn off reminder
                            if !newValue {
                                hasReminder = false
                            }
                        }

                        // Reminder (only available if due date is set)
                        if hasDueDate {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $hasReminder) {
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(.orange)
                                        Text("Set Reminder")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }

                                if hasReminder {
                                    DatePicker("Reminder Time", selection: $reminderTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.compact)

                                    // Show helpful hint
                                    HStack(spacing: 4) {
                                        Image(systemName: "info.circle")
                                            .font(.caption2)
                                        Text("Notification will be sent at this time")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                                .scrollContentBackground(.hidden)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle(existingTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(existingTask == nil ? "Add" : "Save") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(taskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if existingTask == nil {
                    isTextFieldFocused = true
                }
            }
        }
    }

    private func saveTask() {
        let task = Task(
            id: existingTask?.id ?? UUID(),
            title: taskTitle,
            isCompleted: existingTask?.isCompleted ?? false,
            createdAt: existingTask?.createdAt ?? Date(),
            dueDate: hasDueDate ? dueDate : nil,
            category: category.isEmpty ? nil : category,
            priority: selectedPriority,
            notes: notes.isEmpty ? nil : notes,
            hasReminder: hasReminder,
            reminderTime: hasReminder ? reminderTime : nil
        )
        onSave(task)
        dismiss()
    }
}

#Preview {
    TaskManagerView()
}

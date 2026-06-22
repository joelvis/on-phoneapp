//
//  TaskManagerView.swift
//  On phoneapp
//
//  Created by Joel  on 10/18/25.
//

import SwiftUI
import UserNotifications
import Combine
import CoreData
import EventKit

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

    // MARK: Scheduling fields (Phase 2)
    // All default so existing call sites and legacy data keep working.
    var startDate: Date? = nil          // non-nil => this item is "scheduled" (shows on the calendar)
    var endDate: Date? = nil
    var isAllDay: Bool = false
    var recurrenceRule: String? = nil   // iCal RRULE: "FREQ=DAILY" / "FREQ=WEEKLY" / "FREQ=MONTHLY"
    var reminderOffsets: [Int] = []     // minutes-before lead times, e.g. [0, 15, 60]
    var calendarEventID: String? = nil  // EKEvent identifier once mirrored to Apple Calendar
    var notificationIdentifiers: [String] = []
    var textMe: Bool = false            // per-item "send me an SMS" flag
    var updatedAt: Date? = nil

    // Legacy Codable storage (UserDefaults "saved_tasks") only ever held the original
    // fields. Scope Codable to them so old data still decodes; new fields use defaults.
    enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, createdAt, dueDate, category, priority, notes, hasReminder, reminderTime
    }

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), dueDate: Date? = nil, category: String? = nil, priority: Int = 1, notes: String? = nil, hasReminder: Bool = false, reminderTime: Date? = nil, startDate: Date? = nil, endDate: Date? = nil, isAllDay: Bool = false, recurrenceRule: String? = nil, reminderOffsets: [Int] = [], calendarEventID: String? = nil, notificationIdentifiers: [String] = [], textMe: Bool = false, updatedAt: Date? = nil) {
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
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.recurrenceRule = recurrenceRule
        self.reminderOffsets = reminderOffsets
        self.calendarEventID = calendarEventID
        self.notificationIdentifiers = notificationIdentifiers
        self.textMe = textMe
        self.updatedAt = updatedAt
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

    // MARK: Scheduling helpers
    var isScheduled: Bool { startDate != nil }
    var isRecurring: Bool { recurrenceRule != nil }
    var effectiveSortDate: Date? { startDate ?? dueDate }
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

    // Category whose action buttons (Complete / Snooze / Open) appear on reminders.
    static let taskCategoryID = "TASK_REMINDER"

    // Register the interactive actions. Call once at launch before any notification fires.
    func registerCategories() {
        let complete = UNNotificationAction(identifier: "COMPLETE_ACTION", title: "Complete",
                                            options: [.authenticationRequired])
        let snooze = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze 15 min", options: [])
        let open = UNNotificationAction(identifier: "OPEN_ACTION", title: "Open", options: [.foreground])
        let category = UNNotificationCategory(identifier: Self.taskCategoryID,
                                              actions: [complete, snooze, open],
                                              intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
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
        // Attach the interactive actions + the task id so taps/buttons can act on it.
        content.categoryIdentifier = NotificationManager.taskCategoryID
        content.userInfo = ["taskID": task.id.uuidString]

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

// MARK: - Notification Action Handling
// Applies the Complete / Snooze buttons from a notification without the UI being open.
// Works directly against Core Data so it's valid from the AppDelegate callback.
enum TaskActions {
    static func markComplete(taskID: String) {
        let storage = TaskStorageManager()
        guard let uuid = UUID(uuidString: taskID),
              var task = storage.loadTasks().first(where: { $0.id == uuid }) else { return }
        task.isCompleted = true
        storage.saveTask(task)
        NotificationManager.shared.cancelNotification(for: task)
    }

    static func snooze(taskID: String, minutes: Int) {
        let storage = TaskStorageManager()
        guard let uuid = UUID(uuidString: taskID),
              var task = storage.loadTasks().first(where: { $0.id == uuid }) else { return }
        let interval = TimeInterval(minutes * 60)
        if let start = task.startDate { task.startDate = start.addingTimeInterval(interval) }
        if let reminder = task.reminderTime {
            task.reminderTime = reminder.addingTimeInterval(interval)
        } else {
            task.reminderTime = Date().addingTimeInterval(interval)
        }
        task.hasReminder = true
        if let due = task.dueDate { task.dueDate = due.addingTimeInterval(interval) }
        storage.saveTask(task)
        NotificationManager.shared.scheduleNotification(for: task)
    }
}

// MARK: - Calendar Sync (one-way: app -> a dedicated "Joel's App" calendar)
// Mirrors scheduled items for visibility. Never reads or changes the user's own
// calendars, and links each event by identifier so edits update in place (no dupes).
final class CalendarSyncManager {
    static let shared = CalendarSyncManager()
    private let store = EKEventStore()
    private let calendarTitle = "Joel's App"
    private init() {}

    // Ask for calendar permission — called lazily when the user enables the toggle.
    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await store.requestFullAccessToEvents()
            } else {
                return try await store.requestAccess(to: .event)
            }
        } catch {
            print("❌ CalendarSync: access request failed: \(error.localizedDescription)")
            return false
        }
    }

    // Find or create our dedicated calendar so we never touch the user's own calendars.
    private func appCalendar() -> EKCalendar? {
        if let existing = store.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return existing
        }
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = calendarTitle
        calendar.source = store.defaultCalendarForNewEvents?.source
            ?? store.sources.first(where: { $0.sourceType == .local })
            ?? store.sources.first
        do {
            try store.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            print("❌ CalendarSync: failed to create calendar: \(error.localizedDescription)")
            return nil
        }
    }

    // Mirror a scheduled task (visibility only, no separate alarm — the app handles
    // reminders, so you don't get duplicate alerts). Returns the event identifier.
    @discardableResult
    func upsert(_ task: Task) -> String? {
        guard let start = task.startDate ?? task.dueDate else { return nil }
        guard let calendar = appCalendar() else { return nil }

        let event: EKEvent
        if let id = task.calendarEventID, let existing = store.event(withIdentifier: id) {
            event = existing
        } else {
            event = EKEvent(eventStore: store)
        }
        event.calendar = calendar
        event.title = task.title
        event.notes = task.notes
        event.isAllDay = task.isAllDay
        event.startDate = start
        event.endDate = task.endDate ?? start.addingTimeInterval(3600)

        do {
            try store.save(event, span: .thisEvent, commit: true)
            return event.eventIdentifier
        } catch {
            print("❌ CalendarSync: failed to save event: \(error.localizedDescription)")
            return nil
        }
    }

    // Remove the mirrored event when the task is deleted.
    func delete(_ calendarEventID: String?) {
        guard let id = calendarEventID, let event = store.event(withIdentifier: id) else { return }
        try? store.remove(event, span: .thisEvent, commit: true)
    }
}

// MARK: - Main Task Manager View
struct TaskManagerView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false

    private let storageManager = TaskStorageManager()

    // MARK: - Agenda grouping
    struct TaskSection: Identifiable {
        let title: String
        let items: [Task]
        var id: String { title }
        var isOverdue: Bool { title == "Overdue" }
    }

    private func sortByDate(_ a: Task, _ b: Task) -> Bool {
        switch (a.dueDate, b.dueDate) {
        case let (d1?, d2?): return d1 < d2
        case (_?, nil): return true
        case (nil, _?): return false
        default: return a.createdAt > b.createdAt
        }
    }

    private func dayTitle(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month().day())
    }

    // Tasks grouped into an agenda: Overdue, then each upcoming day, then No Date.
    var taskSections: [TaskSection] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dated = tasks.filter { $0.dueDate != nil }
        let undated = tasks.filter { $0.dueDate == nil }

        let overdue = dated.filter { !$0.isCompleted && $0.dueDate! < today }
        let overdueIDs = Set(overdue.map(\.id))
        let remaining = dated.filter { !overdueIDs.contains($0.id) }
        let byDay = Dictionary(grouping: remaining) { cal.startOfDay(for: $0.dueDate!) }

        var sections: [TaskSection] = []
        if !overdue.isEmpty {
            sections.append(TaskSection(title: "Overdue", items: overdue.sorted(by: sortByDate)))
        }
        for day in byDay.keys.sorted() {
            sections.append(TaskSection(title: dayTitle(day), items: (byDay[day] ?? []).sorted(by: sortByDate)))
        }
        if !undated.isEmpty {
            sections.append(TaskSection(title: "No Date", items: undated.sorted { $0.createdAt > $1.createdAt }))
        }
        return sections
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background - light blue in light mode, dark in dark mode
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if tasks.isEmpty {
                        emptyStateView
                    } else {
                        scheduleListView
                    }
                }
            }
            .navigationTitle("Schedule")
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
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))

            Text("Nothing Scheduled")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap + to add a task or schedule something")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Schedule List (agenda grouped by day)
    private var scheduleListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                ForEach(taskSections) { section in
                    Section {
                        ForEach(section.items) { task in
                            TaskRowView(
                                task: task,
                                onToggle: { toggleTaskCompletion(task) },
                                onDelete: { deleteTask(task) },
                                onEdit: { taskToEdit = task }
                            )
                        }
                    } header: {
                        HStack {
                            Text(section.title)
                                .font(.headline)
                                .foregroundColor(section.isOverdue ? .red : .primary)
                            Spacer()
                            Text("\(section.items.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.bar)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
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

        syncToCalendar(task)
    }

    private func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            let oldTask = tasks[index]
            // Preserve links the edit form doesn't carry, so calendar/notifications
            // update in place instead of duplicating.
            var merged = updatedTask
            if merged.calendarEventID == nil { merged.calendarEventID = oldTask.calendarEventID }
            if merged.notificationIdentifiers.isEmpty { merged.notificationIdentifiers = oldTask.notificationIdentifiers }
            tasks[index] = merged
            storageManager.saveTask(merged)

            // Update notification
            if merged.hasReminder {
                scheduleNotificationIfAuthorized(for: merged)
            } else if oldTask.hasReminder && !merged.hasReminder {
                // Cancel notification if reminder was turned off
                notificationManager.cancelNotification(for: merged)
            }

            syncToCalendar(merged)
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
        // Remove the mirrored calendar event, if any
        CalendarSyncManager.shared.delete(task.calendarEventID)

        tasks.removeAll { $0.id == task.id }
        storageManager.deleteTask(task)
    }

    // Mirror a scheduled item into Apple Calendar (one-way), if the user enabled it.
    private func syncToCalendar(_ task: Task) {
        guard calendarSyncEnabled, task.startDate != nil || task.dueDate != nil else { return }
        guard let eid = CalendarSyncManager.shared.upsert(task), eid != task.calendarEventID else { return }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].calendarEventID = eid
        }
        var stored = task
        stored.calendarEventID = eid
        storageManager.saveTask(stored)
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
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
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

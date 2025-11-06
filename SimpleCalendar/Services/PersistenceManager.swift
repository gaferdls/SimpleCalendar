import Foundation
import SwiftData

@MainActor
class PersistenceManager {
    static let shared = PersistenceManager()

    let modelContainer: ModelContainer

    private init() {
        do {
            modelContainer = try ModelContainer(for: Task.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    func fetchTasks() -> [Task] {
        do {
            return try modelContainer.mainContext.fetch(FetchDescriptor<Task>())
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }

    func fetchTasks(for day: Int, in month: Date) -> [Task] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        guard let date = calendar.date(from: components) else { return [] }

        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<Task> { task in
            task.creationDate >= startOfDay && task.creationDate < endOfDay
        }

        let fetchDescriptor = FetchDescriptor<Task>(predicate: predicate)

        do {
            return try modelContainer.mainContext.fetch(fetchDescriptor)
        } catch {
            print("Error fetching tasks for day: \(error)")
            return []
        }
    }

    func addTask(text: String, isBrainDump: Bool) -> Task {
        let newTask = Task(text: text, isBrainDump: isBrainDump)
        modelContainer.mainContext.insert(newTask)
        return newTask
    }

    func addTask(text: String, for day: Int, in month: Date) -> Task {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        let date = calendar.date(from: components) ?? Date()

        let newTask = Task(text: text, creationDate: date, isBrainDump: false)
        modelContainer.mainContext.insert(newTask)
        return newTask
    }

    func deleteTask(_ task: Task) {
        modelContainer.mainContext.delete(task)
    }
}

import Foundation
import SwiftUI
import SwiftData

@MainActor
class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var brainDumpTasks: [Task] = []
    @Published var todaysFocusTasks: [Task] = []
    @Published var currentMonth: Date = Date()
    
    // Gamification Stats
    @AppStorage("totalTasksCompleted") var totalTasksCompleted: Int = 0
    @AppStorage("totalFocusSessions") var totalFocusSessions: Int = 0
    @AppStorage("streakData") var streakDataEncoded: Data = Data()

    @Published var streakData = StreakData() {
        didSet {
            if let encoded = try? JSONEncoder().encode(streakData) {
                streakDataEncoded = encoded
            }
        }
    }
    
    // AI State
    @Published var isGeneratingSubtasks: Bool = false
    @Published var generationError: String?
    
    private var calendar: Calendar{
        Calendar.current
    }
    
    private var persistenceManager: PersistenceManager

    init(persistenceManager: PersistenceManager = .shared){
        self.persistenceManager = persistenceManager
        loadData()
        updateStreakOnLoad()

        if let decoded = try? JSONDecoder().decode(StreakData.self, from: streakDataEncoded) {
            self.streakData = decoded
        }
    }
    
    // MARK: - Data Persistence
    
    func loadData() {
        let allTasks = persistenceManager.fetchTasks()
        self.brainDumpTasks = allTasks.filter { $0.isBrainDump }
        self.todaysFocusTasks = allTasks.filter { !$0.isBrainDump }
    }
    
    // MARK: - Task Management
    
    func completeTask(_ task: Task) {
        if let index = todaysFocusTasks.firstIndex(where: { $0.id == task.id}){
            guard !todaysFocusTasks[index].isCompleted else { return }
            todaysFocusTasks[index].isCompleted = true
            totalTasksCompleted += 1
            updateStreak()
        }
    }
    
    func incrementFocusSessions(){
        totalFocusSessions += 1
    }
    
    func moveTaskToToday(task: Task) {
        task.isBrainDump = false
        brainDumpTasks.removeAll { $0.id == task.id }
        todaysFocusTasks.append(task)
    }
        
    func addBrainDumpTask(text: String) {
        if !text.isEmpty {
            let newTask = persistenceManager.addTask(text: text, isBrainDump: true)
            brainDumpTasks.append(newTask)
        }
    }

    func addTask(text: String, for day: Int) {
        if !text.isEmpty {
            let newTask = persistenceManager.addTask(text: text, for: day, in: currentMonth)
            todaysFocusTasks.append(newTask)
        }
    }

    func tasksForDay(_ day: Int) -> [Task] {
        return persistenceManager.fetchTasks(for: day, in: currentMonth)
    }
        
    func deleteBrainDumpTask(at offsets: IndexSet) {
        for index in offsets {
            let task = brainDumpTasks[index]
            persistenceManager.deleteTask(task)
        }
        brainDumpTasks.remove(atOffsets: offsets)
    }
        
    func deleteTodaysFocusTask(at offsets: IndexSet) {
        for index in offsets {
            let task = todaysFocusTasks[index]
            persistenceManager.deleteTask(task)
        }
        todaysFocusTasks.remove(atOffsets: offsets)
    }
    
    func updateTaskTime(for task: Task, newDate: Date){
        if let index = todaysFocusTasks.firstIndex(where: { $0.id == task.id}){
            todaysFocusTasks[index].startTime = newDate
            todaysFocusTasks.sort { ($0.startTime ?? .distantFuture) < ($1.startTime ?? .distantFuture) }
        }
    }
    
    // MARK: - Gamification
    
    private func updateStreak() {
        guard let lastDate = streakData.lastCompletionDate else {
            // First task ever completed
            streakData.currentStreak = 1
            streakData.lastCompletionDate = Date()
            return
        }
        
        if !calendar.isDateInToday(lastDate) {
            if calendar.isDateInYesterday(lastDate) {
                // Completed a task yesterday, continue the streak
                streakData.currentStreak += 1
            } else {
                // Missed a day, reset streak to 1
                streakData.currentStreak = 1
            }
            streakData.lastCompletionDate = Date()
        }
    }
    
    private func updateStreakOnLoad() {
        guard let lastDate = streakData.lastCompletionDate else { return }
        
        if !calendar.isDateInToday(lastDate) && !calendar.isDateInYesterday(lastDate) {
            streakData.currentStreak = 0
        }
    }
    
    // MARK: - AI Task Decomposition
    
    func decomposeTask(_ task: Task) async {
        DispatchQueue.main.async {
            self.isGeneratingSubtasks = true
            self.generationError = nil
        }

        let apiKey = APIKeyManager.geminiAPIKey
        guard !apiKey.isEmpty else {
            handleDecompositionError(message: "API Key is missing. Please create a 'Secrets.plist' file and add your key.")
            return
        }

        let prompt = """
        Break down the following large task into 3 to 5 smaller, actionable sub-tasks.
        Task: "\(task.text)"
        Provide the response as a JSON object with a single key "subtasks" which contains an array of strings.
        Example: {"subtasks": ["First sub-task", "Second sub-task"]}
        """
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            handleDecompositionError(message: "Invalid API URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody: [String: Any] = ["contents": [["parts": [["text": prompt]]]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                
                if let jsonData = text.data(using: .utf8) {
                    let decodedResponse = try JSONDecoder().decode(AIResponse.self, from: jsonData)
                    
                    DispatchQueue.main.async {
                        // Mark the original task as complete and add the new subtasks to the inbox
                        self.persistenceManager.deleteTask(task)
                        self.brainDumpTasks.removeAll { $0.id == task.id }
                        for subtask in decodedResponse.subtasks {
                            let newTask = self.persistenceManager.addTask(text: "📝 " + subtask, isBrainDump: true)
                            self.brainDumpTasks.append(newTask)
                        }
                        let completedTask = self.persistenceManager.addTask(text: "✅ " + task.text, isBrainDump: false)
                        self.todaysFocusTasks.append(completedTask)
                        self.isGeneratingSubtasks = false
                    }
                }
            } else {
                handleDecompositionError(message: "Could not parse a valid response from the AI. The model may be unavailable.")
            }
        } catch {
            handleDecompositionError(message: "API call failed: \(error.localizedDescription)")
        }
    }
    
    private func handleDecompositionError(message: String) {
        print("Error: \(message)")
        DispatchQueue.main.async {
            self.generationError = message
            self.isGeneratingSubtasks = false
        }
    }
}

fileprivate struct AIResponse: Decodable {
    let subtasks: [String]
}

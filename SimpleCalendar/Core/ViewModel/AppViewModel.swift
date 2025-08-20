//
//  AppViewModel.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/14/25.
//

import Foundation
import SwiftUI

// A simple Decodable struct to match the JSON response we requested
fileprivate struct AIResponse: Decodable {
    let subtasks: [String]
}

class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var allGoals: [String: [DayEntry]] = [:]
    @Published var brainDumpTasks: [DayEntry] = []
    @Published var todaysFocusTasks: [DayEntry] = []
    
    // Gamification Stats
    @Published var totalTasksCompleted: Int = 0
    @Published var totalFocusSessions: Int = 0
    @Published var streakData = StreakData()
    
    // AI State
    @Published var isGeneratingSubtasks: Bool = false
    @Published var generationError: String?
    
    private var calendar: Calendar{
        Calendar.current
    }
    
    init(){
        loadData()
        updateStreakOnLoad()
    }
    
    // MARK: - Data Persistence
    
    func loadData() {
        let loadedData = DataManager.shared.load()
        self.allGoals = loadedData.goalsByDate
        self.brainDumpTasks = loadedData.brainDump
        self.todaysFocusTasks = loadedData.todaysFocus
        self.totalTasksCompleted = loadedData.totalTasksCompleted
        self.totalFocusSessions = loadedData.totalFocusSessions
        self.streakData = loadedData.streakData
    }
    
    func saveData() {
        DataManager.shared.save(
            goalsByDate: allGoals,
            brainDump: brainDumpTasks,
            todaysFocus: todaysFocusTasks,
            totalTasksCompleted: totalTasksCompleted,
            totalFocusSessions: totalFocusSessions,
            streakData: streakData
        )
    }
    
    // MARK: - Task Management
    
    func completeTask(_ task: DayEntry) {
        if let index = todaysFocusTasks.firstIndex(where: { $0.id == task.id}){
            guard !todaysFocusTasks[index].isCompleted else { return }
            todaysFocusTasks[index].isCompleted = true
            totalTasksCompleted += 1
            updateStreak()
            saveData()
        }
    }
    
    func incrementFocusSessions(){
        totalFocusSessions += 1
        saveData()	
    }
    
    func moveTaskToToday(task: DayEntry) {
        todaysFocusTasks.append(task)
        brainDumpTasks.removeAll { $0.id == task.id }
        saveData()
    }
        
    func addBrainDumpTask(_ text: String) {
        if !text.isEmpty {
            let newEntry = DayEntry(text: text)
            brainDumpTasks.append(newEntry)
            saveData()
        }
    }
        
    func deleteBrainDumpTask(at offsets: IndexSet) {
        brainDumpTasks.remove(atOffsets: offsets)
        saveData()
    }
        
    func deleteTodaysFocusTask(at offsets: IndexSet) {
        todaysFocusTasks.remove(atOffsets: offsets)
        saveData()
    }
    
    func updateTaskTime(for task: DayEntry, newDate: Date){
        if let index = todaysFocusTasks.firstIndex(where: { $0.id == task.id}){
            todaysFocusTasks[index].startTime = newDate
            todaysFocusTasks.sort { ($0.startTime ?? .distantFuture) < ($1.startTime ?? .distantFuture) }
            saveData()
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
            saveData()
        }
    }
    
    // MARK: - AI Task Decomposition
    
    func decomposeTask(_ task: DayEntry) async {
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
                    let newTasks = decodedResponse.subtasks.map { DayEntry(text: "📝 " + $0) }
                    
                    DispatchQueue.main.async {
                        // Mark the original task as complete and add the new subtasks to the inbox
                        if let index = self.brainDumpTasks.firstIndex(where: { $0.id == task.id }) {
                            self.brainDumpTasks.remove(at: index)
                            self.brainDumpTasks.insert(contentsOf: newTasks, at: index)
                        } else {
                            // Fallback if the original task wasn't found
                            self.brainDumpTasks.append(contentsOf: newTasks)
                        }
                        
                        let originalTaskEntry = DayEntry(text: "✅ " + task.text, isCompleted: true)
                        self.todaysFocusTasks.append(originalTaskEntry)
                        
                        self.saveData()
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

//
//  AppViewModel.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/14/25.
//

import Foundation
import SwiftUI

class AppViewModel: ObservableObject {
    
    @Published var allGoals: [String: [DayEntry]] = [:]
    @Published var brainDumpTasks: [DayEntry] = []
    @Published var todaysFocusTasks: [DayEntry] = []
    
    // Gomifications Stats
    @Published var totalTasksCompleted: Int = 0
    @Published var streakData = StreakData()
    
    private var calendar: Calendar{
        Calendar.current
    }
    
    init(){
        loadData()
        updateStreakOnLoad()
    }
    
    func loadData() {
        let loadedData = DataManager.shared.load()
        self.allGoals = loadedData.goalsByDate
        self.brainDumpTasks = loadedData.brainDump
        self.todaysFocusTasks = loadedData.todaysFocus
        self.totalTasksCompleted = loadedData.totalTasksCompleted
        self.streakData = loadedData.streakData
    }
    
    func saveData() {
        DataManager.shared.save(
            goalsByDate: allGoals,
            brainDump: brainDumpTasks,
            todaysFocus: todaysFocusTasks,
            totalTasksCompleted: totalTasksCompleted,
            streakData: streakData
        )
    }
    
    func completeTask(_ task: DayEntry) {
        if let index = todaysFocusTasks.firstIndex(where: { $0.id == task.id}){
            guard !todaysFocusTasks[index].isCompleted else { return }
            todaysFocusTasks[index].isCompleted = true
            totalTasksCompleted += 1
            updateStreak()
            saveData()
        }
    }
    
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
}

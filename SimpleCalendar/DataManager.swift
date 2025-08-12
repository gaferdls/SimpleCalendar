//
//  DataManager.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import Foundation

struct GoalData: Codable {
    var goalsByDate: [String: [DayEntry]]
}

struct DayEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var isPriority: Bool = false
}

class DataManager{
    static let shared = DataManager()
    
    private let fileName = "goals.json"
    
    private init() {}
    
    private var fileURL: URL?{
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentDirectory?.appendingPathComponent(fileName)
    }
    
    func save(goalsByDate: [String: [DayEntry]]){
        guard let url = fileURL else { return }
        let cleanedGoalsByDate = goalsByDate.mapValues {entries in
            entries.filter{!$0.text.isEmpty}}
        let dataToSave = GoalData(goalsByDate: cleanedGoalsByDate)
        let encoder = JSONEncoder()
        do{
            let data = try encoder.encode(dataToSave)
            try data.write(to: url)
            print("Goals saved succesfully")
        } catch{
            print("Error saving goals: \(error.localizedDescription)")
        }
    }
    
    func load() -> [String: [DayEntry]]{
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else{
            return [:]
        }
        
        let decoder = JSONDecoder()
        do{
            let decodeData = try decoder.decode(GoalData.self, from: data)
            print("Goals loaded sucessfully")
            return decodeData.goalsByDate
        } catch{
            print("Error loading goals: \(error.localizedDescription)")
            return [:]
        }
    }
}

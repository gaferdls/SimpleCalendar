//
//  DayDetailView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI

struct DayDetailView: View {
    let selectedDay : Int
    var onGoalsUpdated: () -> Void
    
    @State private var newGoal = ""
    @State private var goals: [DayEntry] = []
    @State private var selectedType: String = "Goal"
    @State private var isGeneratingTask: Bool = false
    
    private let types = ["Goal", "Reminder"]
    
    private var dateFormatter: DateFormatter{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    private var dateKey: String{
        let today = Date()
        var components = Calendar.current.dateComponents([.year, .month], from: today)
        components.day = selectedDay
        let selectedDate = Calendar.current.date(from: components) ?? today
        return dateFormatter.string(from: selectedDate)
    }
    
    
    var body: some View{
        VStack{
            Picker("Type", selection: $selectedType){
                ForEach(types, id: \.self){ type in
                    Text(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            HStack{
                TextField("Add a new goal ...", text: $newGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if newGoal.count > 10 {
                    Button(action:{
                        Task{
                            await generateSubtasks()
                        }
                    }){
                        Text("Decompose")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(isGeneratingTask)
                }else{
                    Button(action:{
                        if !newGoal.isEmpty{
                            let emoji = selectedType == "Goal" ? "🎯" : "⏰"
                            let newEntry = DayEntry(text: emoji + newGoal, isPriority: false)
                            goals.append(newEntry)
                            newGoal = ""
                            saveGoals()
                        }
                    }){
                        Text("Add")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            if isGeneratingTask{
                ProgressView()
                    .padding()
            }
            
            if !goals.isEmpty{
                Text("Goals for Day \(selectedDay)")
                    .font(.headline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            List{
                ForEach(goals){ entry in
                    HStack{
                        Text(entry.text)
                        Spacer()
                        Button(action:{
                            togglePriority(for: entry)
                        }){
                            Image(systemName: entry.isPriority ? "star.fill" : "star")
                                .foregroundColor(entry.isPriority ? .yellow : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete(perform: deleteGoals)
            }
            .listStyle(.inset)
            Spacer()
        }
        .onAppear{
            loadGoals()
        }
        .navigationTitle("Day \(selectedDay)")
        .toolbar{
            if !goals.isEmpty{
                EditButton()
            }
        }
    }
    
    func generateSubtasks() async{
        isGeneratingTask = true
        let apiKey = "" // API key is provided by the system.
        let prompt = """
                    Break down the following large task into 3 to 5 smaller, actionable sub-tasks.
                    Provide the sub-tasks as a bulleted list.
                    Task: \(newGoal)
                    """
        
        
        let chatHistory: [[String: Any]] = [["role": "user", "parts": [["text": prompt]]]]
        
        
        let payload = ["contents": chatHistory]
        let apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=\(apiKey)"
        do{
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: URL(string: apiUrl)!))
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let candidates = json["candidates"] as? [[String: Any]],
                           let content = candidates.first?["content"] as? [String: Any],
                           let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                
                // Parse the bulleted list into individual tasks.
                let newTasks = text.split(separator: "\n").compactMap { subtask in
                    let trimmedTask = subtask.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "")
                    return trimmedTask.isEmpty ? nil : DayEntry(text: "📝 " + trimmedTask)
                }
                
                // Add the original task and the new sub-tasks to the list.
                let originalTaskEntry = DayEntry(text: "✅ " + newGoal, isPriority: false)
                goals.append(originalTaskEntry)
                goals.append(contentsOf: newTasks)
                
                newGoal = "" // Clear the input field.
                saveGoals() // Save the updated list.
            }
        
        } catch {
            print("Erorr during API call: \(error.localizedDescription)")
            let originalTaskEntry = DayEntry(text: "✅ " + newGoal, isPriority: false)
            goals.append(originalTaskEntry)
            newGoal = ""
            saveGoals()
        }
        isGeneratingTask = false
    }
    
    private func loadGoals(){
        let loadedData = DataManager.shared.load()
        self.goals = loadedData.goalsByDate[dateKey] ?? []
    }
    
    private func saveGoals(){
        var loadedData = DataManager.shared.load()
        loadedData.goalsByDate[dateKey] = self.goals
        DataManager.shared.save(goalsByDate: loadedData.goalsByDate, brainDump: loadedData.brainDump, todaysFocus: loadedData.todaysFocus)
        onGoalsUpdated()
    }
    
    private func deleteGoals(at offsets: IndexSet){
        goals.remove(atOffsets: offsets)
        saveGoals()
    }
    
    private func togglePriority(for entry: DayEntry){
        if let index = goals.firstIndex(where: { $0.id == entry.id}){
            goals[index].isPriority.toggle()
            saveGoals()
        }
    }
    
}

struct DayDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DayDetailView(selectedDay: 15, onGoalsUpdated: {})
    }
}

//
//  DayDetailView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI

fileprivate struct AIResponse: Decodable {
    let subtasks: [String]
}

class APIKeyManager {
    static var geminiAPIKey: String {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            print("ERROR: Secrets.plist not found or could not be loaded. Please create one and add your 'GeminiAPIKey'.")
            return ""
        }
        return plist["GeminiAPIKey"] as? String ?? ""
    }
}
    
struct DayDetailView: View {
    let selectedDay : Int
    var onGoalsUpdated: () -> Void
    
    // State for thje view
    @State private var newGoal = ""
    @State private var goals: [DayEntry] = []
    @State private var selectedType: String = "Goal"
    @State private var isGeneratingTask: Bool = false
    
    // State for error handling
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
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
                TextField("Add a new goal...", text: $newGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // The "Decompose" button appears for longer tasks
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
                        addGoal()
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
                ProgressView("Braking it down...")
                    .padding()
            }
            if !goals.isEmpty{
                Text("Tasks for Day \(selectedDay)")
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
        .alert("Error", isPresented: $showingErrorAlert){
            Button("OK"){}
        } message: {
            Text(errorMessage)
        }
    }
    
    // Functions
    
    func addGoal() {
        if !newGoal.isEmpty{
            let emoji = selectedType == "Goal" ? "🎯" : "⏰"
            let newEntry = DayEntry(text: emoji + " " + newGoal, isPriority: false)
            goals.append(newEntry)
            newGoal = ""
            saveGoals()
        }
    }
    
    func generateSubtasks() async {
        isGeneratingTask = true
        
        let apiKey = APIKeyManager.geminiAPIKey
        guard !apiKey.isEmpty else {
            handleError(message: "API Key is missing. Please add it to Secrets.plist.")
            return
        }
        
        let prompt = """
            Break down the following large task into 3 to 5 smaller, actionable sub-tasks.
            Task: "\(newGoal)"
            Provide the response as a JSON object with a single key "subtasks" which contains an array of strings.
            Example: {"subtasks": ["First sub-task", "Second sub-task"]}
            """
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            handleError(message: "Invalid API URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody: [String: Any] = ["contents": [["parts": [["text": prompt]]]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Parse the top-level Gemini response
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                
                // Decode the JSON string from the "text" field
                if let jsonData = text.data(using: .utf8) {
                    let decodedResponse = try JSONDecoder().decode(AIResponse.self, from: jsonData)
                    let newTasks = decodedResponse.subtasks.map { DayEntry(text: "📝 " + $0) }
                    
                    // Update UI on the main thread
                    DispatchQueue.main.async {
                        let originalTaskEntry = DayEntry(text: "✅ " + newGoal, isPriority: false)
                        self.goals.append(originalTaskEntry)
                        self.goals.append(contentsOf: newTasks)
                        self.newGoal = ""
                        self.saveGoals()
                        self.isGeneratingTask = false
                    }
                }
            } else {
                handleError(message: "Could not parse a valid response from the AI.")
            }
        } catch {
            handleError(message: "API call failed: \(error.localizedDescription)")
        }
    }
    
    private func handleError(message: String){
        print("Error: \(message)")
        DispatchQueue.main.async{
            self.errorMessage = message
            self.showingErrorAlert = true
            self.isGeneratingTask = false
        }
    }
    
    // Data Parsistence
    
    private func loadGoals(){
        let loadedData = DataManager.shared.load()
        self.goals = loadedData.goalsByDate[dateKey] ?? []
    }
    
    private func saveGoals(){
        var allData = DataManager.shared.load()
        allData.goalsByDate[dateKey] = self.goals
        
        DataManager.shared.save(
            goalsByDate: allData.goalsByDate,
            brainDump: allData.brainDump,
            todaysFocus: allData.todaysFocus,
            totalTasksCompleted: allData.totalTasksCompleted,
            streakData: allData.streakData
        )
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
        NavigationStack {
            DayDetailView(selectedDay: 15, onGoalsUpdated: {})
        }
    }
}


//
//  DayDetailView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI

// A simple Decodable struct to match the JSON response we requested
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
    // Access the shared ViewModel
    @EnvironmentObject var viewModel: AppViewModel
    
    let selectedDay : Int
    
    // State for the view (UI-specific)
    @State private var newGoal = ""
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
    
    private var goalsForDay: [DayEntry] {
        viewModel.allGoals[dateKey] ?? []
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
                ProgressView("Breaking it down...")
                    .padding()
            }
            
            if !goalsForDay.isEmpty{
                Text("Tasks for Day \(selectedDay)")
                    .font(.headline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            List{
                ForEach(goalsForDay){ entry in
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
        .navigationTitle("Day \(selectedDay)")
        .toolbar{
            if !goalsForDay.isEmpty{
                EditButton()
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Functions
    
    func addGoal() {
        if !newGoal.isEmpty{
            let emoji = selectedType == "Goal" ? "🎯" : "⏰"
            let newEntry = DayEntry(text: emoji + " " + newGoal, isPriority: false)
            viewModel.allGoals[dateKey, default: []].append(newEntry)
            newGoal = ""
            viewModel.saveData()
        }
    }
    
    func generateSubtasks() async {
        isGeneratingTask = true
        let apiKey = APIKeyManager.geminiAPIKey
        guard !apiKey.isEmpty else {
            handleError(message: "API Key is missing. Please create a 'Secrets.plist' file and add your key.")
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
            
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                
                if let jsonData = text.data(using: .utf8) {
                    let decodedResponse = try JSONDecoder().decode(AIResponse.self, from: jsonData)
                    let newTasks = decodedResponse.subtasks.map { DayEntry(text: "📝 " + $0) }
                    
                    DispatchQueue.main.async {
                        let originalTaskEntry = DayEntry(text: "✅ " + newGoal, isPriority: false)
                        viewModel.allGoals[dateKey, default: []].append(originalTaskEntry)
                        viewModel.allGoals[dateKey, default: []].append(contentsOf: newTasks)
                        self.newGoal = ""
                        viewModel.saveData()
                        self.isGeneratingTask = false
                    }
                }
            } else {
                handleError(message: "Could not parse a valid response from the AI. The model may be unavailable.")
            }
        } catch {
            handleError(message: "API call failed: \(error.localizedDescription)")
        }
    }
    
    private func handleError(message: String) {
        print("Error: \(message)")
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showingErrorAlert = true
            self.isGeneratingTask = false
        }
    }
    
    // MARK: - Data Persistence
    
    private func deleteGoals(at offsets: IndexSet){
        viewModel.allGoals[dateKey]?.remove(atOffsets: offsets)
        viewModel.saveData()
    }
    
    private func togglePriority(for entry: DayEntry){
        if let index = viewModel.allGoals[dateKey]?.firstIndex(where: { $0.id == entry.id }){
            viewModel.allGoals[dateKey]?[index].isPriority.toggle()
            viewModel.saveData()
        }
    }
}

struct DayDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DayDetailView(selectedDay: 15)
                .environmentObject(AppViewModel())
        }
    }
}

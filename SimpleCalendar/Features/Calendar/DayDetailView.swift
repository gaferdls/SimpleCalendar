//
//  DayDetailView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI

struct DayDetailView: View {
    // Access the shared ViewModel
    @EnvironmentObject var viewModel: AppViewModel
    
    let selectedDay : Int
    
    // State for the view (UI-specific)
    @State private var newGoal = ""
    @State private var selectedType: String = "Goal"
    
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
                
                // The "Decompose" button has been removed.
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
            .padding()
            
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

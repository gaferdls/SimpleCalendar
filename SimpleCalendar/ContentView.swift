//
//  ContentView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentDate = Date()
    @State private var selectedDay: Int?
    @State private var allGoals: [String: [DayEntry]] = [:]
    @State private var brainDumpTasks: [DayEntry] = []
    @State private var newBrainDumpTask: String = ""
    @State private var todaysFocusTasks: [DayEntry] = []
    @State private var selectedTaskForTime: DayEntry?
    
    private var calendar: Calendar{
        Calendar.current
    }
    
    private func numberOfDays(in date: Date) -> Int{
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    private func firstDayOfMonth(in date: Date) -> Int{
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return calendar.component(.weekday, from: firstDay)
    }
    
    private func headerText(for date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack{
            VStack { // This is the main VStack for the entire screen
                VStack(alignment: .leading) {
                    Text(headerText(for: currentDate))
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    HStack(spacing: 0){
                        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                        ForEach(weekdays, id: \.self) {day in
                            Text(day)
                                .font(.footnote)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    Grid(horizontalSpacing: 0, verticalSpacing: 10){
                        let leadingBlanks = firstDayOfMonth(in: currentDate) - 1
                        let totalDays = numberOfDays(in: currentDate)
                        let totalCells = leadingBlanks + totalDays
                        let totalRows = (totalCells + 6 ) / 7
                        
                        ForEach(0..<totalRows, id: \.self) {row in
                            GridRow{
                                ForEach(0..<7, id: \.self) {col in
                                    let index = row * 7 + col
                                    
                                    if index < leadingBlanks || (index - leadingBlanks + 1) > totalDays{
                                        Text("")
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        let dayNumber = index - leadingBlanks + 1
                                        
                                        NavigationLink(value: dayNumber) {
                                            VStack(spacing: 4) {
                                                Text("\(dayNumber)")
                                                    .font(.body)
                                                    .frame(width: 30, height: 30)
                                                    .background(isToday(day: dayNumber) ? Color.blue.opacity(0.8) : Color.clear)
                                                    .foregroundColor(isToday(day: dayNumber) ? .white : .black)
                                                    .clipShape(Circle())
                                                
                                                if hasGoal(for: dayNumber) {
                                                    Circle()
                                                        .fill(Color.blue)
                                                        .frame(width: 6, height: 6)
                                                } else {
                                                    Circle()
                                                        .fill(Color.clear)
                                                        .frame(width: 6, height: 6)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(.plain)
                                            .tint(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // MARK: Bottom Section - Today's Focus & Brain Dump
                    List {
                        Section(header: Text("Today's Focus").font(.title2).fontWeight(.bold).padding(.leading, -16)) {
                            ForEach(todaysFocusTasks) { task in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        if let time = task.startTime {
                                            Text(time, style: .time)
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                                .frame(width: 60, alignment: .leading)
                                        } else {
                                            Text("No Time")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                                .frame(width: 60, alignment: .leading)
                                        }
                                        Text(task.text)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle()) // Make the whole row tappable
                                    .onTapGesture {
                                        // Toggle the DatePicker for this task
                                        selectedTaskForTime = (selectedTaskForTime?.id == task.id) ? nil : task
                                    }
                                    
                                    // The DatePicker will only appear if its task is the one selected.
                                    if selectedTaskForTime?.id == task.id {
                                        DatePicker("", selection: Binding(
                                            get: { selectedTaskForTime?.startTime ?? Date() },
                                            set: { newDate in
                                                updateTaskTime(for: task, newDate: newDate)
                                            }
                                        ), displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .datePickerStyle(.wheel)
                                    }
                                }
                            }
                            .onDelete(perform: deleteTodaysFocusTask)
                        }
                        
                        Section(header: Text("Brain Dump").font(.title2).fontWeight(.bold).padding(.leading, -16)) {
                            HStack {
                                TextField("Quick-add a thought...", text: $newBrainDumpTask)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button(action: {
                                    if !newBrainDumpTask.isEmpty {
                                        let newEntry = DayEntry(text: newBrainDumpTask)
                                        brainDumpTasks.append(newEntry)
                                        newBrainDumpTask = ""
                                        saveAllData()
                                    }
                                }) {
                                    Text("Add")
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            
                            ForEach(brainDumpTasks) { task in
                                HStack {
                                    Text(task.text)
                                    Spacer()
                                    Button(action: {
                                        moveTaskToToday(task: task)
                                    }) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .onDelete(perform: deleteBrainDumpTask)
                        }
                    }
                    .listStyle(.insetGrouped)
                    
                }
                .onAppear {
                    let loadedData = DataManager.shared.load()
                    self.allGoals = loadedData.goalsByDate
                    self.brainDumpTasks = loadedData.brainDump
                    self.todaysFocusTasks = loadedData.todaysFocus
                }
                .navigationDestination(for: Int.self) { day in
                    DayDetailView(selectedDay: day, onGoalsUpdated: {
                        self.allGoals = DataManager.shared.load().goalsByDate
                        print("Goals were updated! Reloading the calendar.")
                    })
                }
                .navigationTitle("Calendar")
                .popover(item: $selectedTaskForTime) { task in
                    VStack {
                        Text("Set a time for: \(task.text)")
                            .font(.headline)
                            .padding()
                        
                        DatePicker("", selection: Binding(
                            get: { selectedTaskForTime?.startTime ?? Date() },
                            set: { newDate in
                                updateTaskTime(for: task, newDate: newDate)
                                if let index = todaysFocusTasks.firstIndex(where: { $0.id == task.id }) {
                                    selectedTaskForTime = todaysFocusTasks[index]
                                }
                            }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .padding()
                        
                        Button("Done") {
                            selectedTaskForTime = nil
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
    
    func isToday(day: Int) -> Bool{
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentDate)
        
        return components.day == day && components.month == currentMonthComponents.month && components.year == currentMonthComponents.year
    }
    
    private func dateKey(for day: Int) -> String{
        let today = Date()
        var components = calendar.dateComponents([.year, .month], from: today)
        components.day = day
        let selectedDate = Calendar.current.date(from: components) ?? today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private func hasGoal (for day: Int) -> Bool{
        let key = dateKey(for: day)
        return !(allGoals[key] ?? []).isEmpty
    }
    
    private func saveAllData() {
        DataManager.shared.save(goalsByDate: allGoals, brainDump: brainDumpTasks, todaysFocus: todaysFocusTasks)
    }
    
    private func deleteBrainDumpTask(at offsets: IndexSet) {
        brainDumpTasks.remove(atOffsets: offsets)
        saveAllData()
    }
    
    private func deleteTodaysFocusTask(at offsets: IndexSet) {
        todaysFocusTasks.remove(atOffsets: offsets)
        saveAllData()
    }
    
    private func moveTaskToToday(task: DayEntry) {
        todaysFocusTasks.append(task)
        if let index = brainDumpTasks.firstIndex(where: { $0.id == task.id }) {
            brainDumpTasks.remove(at: index)
        }
        saveAllData()
    }
    
    private func updateTaskTime(for task: DayEntry, newDate: Date){
        if let index = todaysFocusTasks.firstIndex(where: { $0.id == task.id}){
            todaysFocusTasks[index].startTime = newDate
            todaysFocusTasks.sort { $0.startTime ?? Date() < $1.startTime ?? Date() }
            saveAllData()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View{
        ContentView()
    }
}

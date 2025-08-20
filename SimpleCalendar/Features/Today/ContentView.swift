//
//  ContentView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/14/25.
//

import SwiftUI

// ContentView is now the "Today's Focus" screen.
struct ContentView: View {
    
    // Access the shared ViewModel from the enviorment
    @EnvironmentObject var viewModel: AppViewModel
    
    // Ui-specific state can remin here.
    @State private var justCompletedTask: DayEntry?
    @State private var selectedTaskForTime: DayEntry?
    @State private var activeTask: DayEntry?
    @State private var showingBrainDumpSheet = false
    
    // A formatter for the main date display.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d" // e.g., "Thursday, August 14"
        return formatter
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing){
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Header
                        VStack(alignment: .leading) {
                            Text("Today")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text(dateFormatter.string(from: Date()))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding([.horizontal, .top])
                        
                        // MARK: - Stats View
                        
                        StatsView(totalCompleted: viewModel.totalTasksCompleted, currentStreak: viewModel.streakData.currentStreak)
                                .padding(.horizontal)
                        
                        // MARK: - Progress Bar
                        VStack(alignment: .leading) {
                            Text("Daily Progress")
                                .font(.headline)
                            
                            let totalTasks = viewModel.todaysFocusTasks.count
                            let completedTasks = viewModel.todaysFocusTasks.filter { $0.isCompleted }.count
                            let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
                            
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            Text("\(completedTasks) / \(totalTasks) tasks complete!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // MARK: - Today's Task List
                        VStack(alignment: .leading) {
                            Text("Today's Agenda")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            // This now filters out completed tasks so they "disappear" from the active list.
                            ForEach(viewModel.todaysFocusTasks.filter { !$0.isCompleted }) { task in
                                TodayTaskRow(
                                    task: task,
                                    onComplete: { completedTask in
                                        if !completedTask.isCompleted {
                                            justCompletedTask = completedTask
                                        }
                                        viewModel.completeTask(completedTask)
                                    },
                                    onSelectTime: { selectedTask in
                                        self.selectedTaskForTime = selectedTask
                                    },
                                    onLongPress: { pressedTask in
                                        self.activeTask = pressedTask
                                    }
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer().frame(height: 80)
                    }
                }
                
                .padding()
                
                .navigationTitle("Focus")
                .navigationBarHidden(true)
                .popover(item: $selectedTaskForTime) { task in
                    // This popover allows setting a time for a task.
                    VStack {
                        Text("Set a time for: \(task.text)")
                            .font(.headline)
                            .padding()
                        
                        DatePicker("", selection: Binding(
                            get: { selectedTaskForTime?.startTime ?? Date() },
                            set: { newDate in
                                viewModel.updateTaskTime(for: task, newDate: newDate)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .padding()
                        
                        Button("Done") {
                            selectedTaskForTime = nil
                        }
                        .padding()
                    }
                }
                .overlay(
                    ZStack {
                        TimerOverlay(activeTask: $activeTask)
                        CelebrationView(trigger: $justCompletedTask)
                            .ignoresSafeArea()
                    }
                )
                .sensoryFeedback(.success, trigger: justCompletedTask)
                
                Button(action: {
                    showingBrainDumpSheet = true
                }){
                    Image(systemName: "plus")
                        .font(.title.weight(.semibold))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4, x: 0, y: 4)
                }
            }
        }
    }
}

// MARK: - Reusable Helper Views

private struct BrainDumpEntryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var newThought: String = ""
    
    var body: some View{
        NavigationStack{
            VStack{
                TextField("What's on your mind?", text: $newThought, axis: .vertical)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                Spacer()
            }
            .padding()
            .navigationTitle("Brain Dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction){
                    Button("Cancel"){
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction){
                    Button("Save"){
                        viewModel.addBrainDumpTask(newThought)
                        dismiss()
                    }
                    .disabled(newThought.isEmpty)
                }
            }
        }
    }
}

struct TodayTaskRow: View {
    let task: DayEntry
    var onComplete: (DayEntry) -> Void
    var onSelectTime: (DayEntry) -> Void
    var onLongPress: (DayEntry) -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: { onComplete(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .blue)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text(task.text)
                    .font(.headline)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let time = task.startTime {
                    Text(time, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelectTime(task) }
        .onLongPressGesture { onLongPress(task) }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct TimerOverlay: View {
    @Binding var activeTask: DayEntry?

    var body: some View {
        if let task = activeTask {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        activeTask = nil
                    }

                PomodoroTimerView(activeTask: task) {
                    activeTask = nil
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}

//
//  ContentView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI
import AVFoundation

// Calendar View is now the old Content View 

struct CalendarView: View {
    
    @EnvironmentObject var viewModel: AppViewModel
    
    // UI Interaction State
    @State private var currentDate = Date()
    @State private var selectedDay: Int?
    @State private var newBrainDumpTask: String = ""
    @State private var selectedTaskForTime: DayEntry?
    @State private var activeTask: DayEntry?
    @State private var justCompletedTask: DayEntry?
    
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
            VStack {
                StatsView(totalCompleted: viewModel.totalTasksCompleted, currentStreak: viewModel.streakData.currentStreak)
                    .padding(.bottom)
                
                // MARK: Calendar Grid
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
                
                List {
                    Section(header: Text("Today's Focus").font(.title2).fontWeight(.bold).padding(.leading, -16)) {
                        ForEach(viewModel.todaysFocusTasks) { task in
                            TodayTaskRow(task: task, onComplete: { completedTask in
                                justCompletedTask = completedTask
                                viewModel.completeTask(completedTask)
                            }, onSelectTime: { selectedTask in
                                selectedTaskForTime = (selectedTaskForTime?.id == selectedTask.id) ? nil : selectedTask
                            }, onLongPress: { pressedTask in
                                activeTask = pressedTask
                            })
                        }
                        .onDelete(perform: viewModel.deleteTodaysFocusTask)
                    }
                    
                    Section(header: Text("Brain Dump").font(.title2).fontWeight(.bold).padding(.leading, -16)) {
                        HStack {
                            TextField("Quick-add a thought...", text: $newBrainDumpTask)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                viewModel.addBrainDumpTask(newBrainDumpTask)
                                newBrainDumpTask = "" // Clear the text field
                            }) {
                                Text("Add")
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        ForEach(viewModel.brainDumpTasks) { task in
                            HStack {
                                Text(task.text)
                                Spacer()
                                Button(action: {
                                    viewModel.moveTaskToToday(task: task)
                                }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .onDelete(perform: viewModel.deleteBrainDumpTask)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationDestination(for: Int.self) { day in
                DayDetailView(selectedDay: day)
            }
            .navigationTitle("Calendar")
            .popover(item: $selectedTaskForTime) { task in
                // This popover logic remains the same as it's view-specific.
                VStack {
                    Text("Set a time for: \(task.text)")
                        .font(.headline)
                        .padding()
                    
                    DatePicker("", selection: Binding(
                        get: { selectedTaskForTime?.startTime ?? Date() },
                        set: { newDate in
                            // We'll need a new function in the viewModel for this.
                            // updateTaskTime(for: task, newDate: newDate)
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
            .overlay(
                ZStack {
                    TimerOverlay(activeTask: $activeTask)
                    CelebrationView(trigger: $justCompletedTask)
                        .ignoresSafeArea()
                }
            )
            .sensoryFeedback(.success, trigger: justCompletedTask)
            .animation(.easeInOut, value: activeTask)
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
        return !(viewModel.allGoals[key] ?? []).isEmpty
    }
}
struct StatsView: View {
    let totalCompleted: Int
    let currentStreak: Int
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("\(totalCompleted)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Completed")
                    .font(.caption)
            }
            Spacer()
            VStack {
                Text("\(currentStreak)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Day Streak 🔥")
                    .font(.caption)
            }
            Spacer()
        }
        .padding(.horizontal)
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
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                if let time = task.startTime {
                    Text(time, style: .time)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Text(task.text)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelectTime(task) }
        .onLongPressGesture { onLongPress(task) }
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

struct CelebrationView: View {
    @Binding var trigger: DayEntry?
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isAnimating {
                    ForEach(0..<150) { _ in
                        ParticleView(size: geometry.size)
                    }
                }
            }
        }
        .onChange(of: trigger) { oldValue, newValue in
            guard newValue != nil else { return }
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isAnimating = false
                trigger = nil
            }
        }
    }
}

struct ParticleView: View {
    let size: CGSize
    @State private var isAnimating = false
    
    private let colors: [Color] = [.blue, .green, .red, .orange, .purple, .yellow]
    private let startX: CGFloat
    private let startY: CGFloat
    private let endY: CGFloat
    private let scale: CGFloat
    private let duration: Double
    private let delay: Double

    init(size: CGSize) {
        self.size = size
        self.startX = .random(in: 0...size.width)
        self.startY = size.height + 50
        self.endY = .random(in: -50...size.height/2)
        self.scale = .random(in: 0.5...1.5)
        self.duration = .random(in: 0.8...1.5)
        self.delay = .random(in: 0...0.3)
    }

    var body: some View {
        Circle()
            .fill(colors.randomElement()!)
            .frame(width: 15, height: 15)
            .scaleEffect(isAnimating ? scale : 0)
            .position(x: startX, y: isAnimating ? endY : startY)
            .animation(.easeOut(duration: duration).delay(delay), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

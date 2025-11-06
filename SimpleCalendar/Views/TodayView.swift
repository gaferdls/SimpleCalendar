import SwiftUI

struct TodayView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var justCompletedTask: Task?
    @State private var selectedTaskForTime: Task?
    @State private var activeTask: Task?
    @State private var showingBrainDumpSheet = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing){
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading) {
                            Text("Today")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text(dateFormatter.string(from: Date()))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding([.horizontal, .top])
                        
                        StatsView(totalCompleted: viewModel.totalTasksCompleted, currentStreak: viewModel.streakData.currentStreak)
                                .padding(.horizontal)
                        
                        Text("Daily Progress")
                            .font(.headline)
                            .padding(.horizontal)

                        let totalTasks = viewModel.todaysFocusTasks.count
                        let completedTasks = viewModel.todaysFocusTasks.filter { $0.isCompleted }.count
                        let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0

                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .padding(.horizontal)

                        Text("\(completedTasks) / \(totalTasks) tasks complete!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Today's Agenda")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
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
            .sheet(isPresented: $showingBrainDumpSheet) {
                BrainDumpView()
            }
        }
    }
}

struct TodayTaskRow: View {
    let task: Task
    var onComplete: (Task) -> Void
    var onSelectTime: (Task) -> Void
    var onLongPress: (Task) -> Void
    
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
    @Binding var activeTask: Task?

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

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
            .environmentObject(AppViewModel())
    }
}

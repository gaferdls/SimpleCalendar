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
    
    // A formatter for the main date display.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d" // e.g., "Thursday, August 14"
        return formatter
    }

    var body: some View {
        NavigationStack {
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
                    .padding(.horizontal)
                    
                    // MARK: - Progress Bar (Placeholder)
                    VStack(alignment: .leading) {
                        Text("Daily Progress")
                            .font(.headline)
                        
                        // Calculate progress based on live data.
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
                        
                        // The list now iterates over the tasks from the viewModel.
                        ForEach(viewModel.todaysFocusTasks) { task in
                            HStack {
                                Button(action: {
                                    justCompletedTask = task
                                    viewModel.completeTask(task)
                                }) {
                                    Image(systemName: "circle")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                
                                VStack(alignment: .leading) {
                                    Text(task.text)
                                        .font(.headline)
                                    if let time = task.startTime {
                                        Text(time, style: .time)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Focus")
            .navigationBarHidden(true)
            .overlay(
                CelebrationView(trigger: $justCompletedTask)
                    .ignoresSafeArea()
            )
            .sensoryFeedback(.success, trigger: justCompletedTask)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}

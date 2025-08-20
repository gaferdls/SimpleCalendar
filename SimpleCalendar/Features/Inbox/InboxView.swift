//
//  InboxView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/20/25.
//

import SwiftUI

struct InboxView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var taskToDecompose: DayEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.brainDumpTasks.isEmpty {
                    VStack {
                        Image(systemName: "tray.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Your inbox is empty!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                        Text("Use the '+' on the 'Today' screen to add new thoughts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(viewModel.brainDumpTasks) { task in
                            InboxTaskRow(
                                task: task,
                                onMoveToToday: {
                                    viewModel.moveTaskToToday(task: task)
                                },
                                onDecompose: {
                                    taskToDecompose = task
                                }
                            )
                        }
                        .onDelete(perform: viewModel.deleteBrainDumpTask)
                    }
                    .listStyle(.plain)
                }

                if viewModel.isGeneratingSubtasks {
                    ProgressView("Breaking it down...")
                        .padding(25)
                        .background(.thickMaterial)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                if !viewModel.brainDumpTasks.isEmpty {
                    EditButton()
                }
            }
            .onChange(of: taskToDecompose) { _, newValue in
                if let task = newValue {
                    Task {
                        await viewModel.decomposeTask(task)
                        taskToDecompose = nil
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.generationError != nil), actions: {
                Button("OK") { viewModel.generationError = nil }
            }, message: {
                Text(viewModel.generationError ?? "An unknown error occurred.")
            })
        }
    }
}

struct InboxTaskRow: View {
    let task: DayEntry
    var onMoveToToday: () -> Void
    var onDecompose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(task.text)
                .font(.body)

            HStack(spacing: 15) {
                Button(action: onMoveToToday) {
                    Label("Schedule Today", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                if task.text.count > 10 {
                    Button(action: onDecompose) {
                        Label("Decompose", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

struct InboxView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AppViewModel()
        viewModel.brainDumpTasks = [
            DayEntry(text: "Plan the entire company offsite event"),
            DayEntry(text: "Call the dentist"),
            DayEntry(text: "Think about vacation ideas")
        ]
        return InboxView().environmentObject(viewModel)
    }
}

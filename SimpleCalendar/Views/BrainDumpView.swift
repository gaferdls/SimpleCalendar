import SwiftUI

struct BrainDumpView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var newEntryText = ""
    @State private var taskToDecompose: Task?

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isGeneratingSubtasks {
                    VStack {
                        Text("Decomposing task...")
                        ProgressView()
                    }
                } else {
                    List {
                        ForEach(viewModel.brainDumpTasks) { task in
                            BrainDumpEntryView(
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
                }

                HStack {
                    TextField("Add a new task...", text: $newEntryText)
                        .textFieldStyle(.roundedBorder)

                    Button(action: {
                        viewModel.addBrainDumpTask(text: newEntryText)
                        newEntryText = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    .disabled(newEntryText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Brain Dump")
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

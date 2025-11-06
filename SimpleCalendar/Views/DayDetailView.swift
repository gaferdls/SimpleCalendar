import SwiftUI
import SwiftData

struct DayDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let selectedDay: Int
    @State private var newTaskText = ""

    private var tasksForDay: [Task] {
        return viewModel.tasksForDay(selectedDay)
    }

    var body: some View {
        VStack {
            List {
                ForEach(tasksForDay) { task in
                    Text(task.text)
                }
            }

            HStack {
                TextField("Add a new task...", text: $newTaskText)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    viewModel.addTask(text: newTaskText, for: selectedDay)
                    newTaskText = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
                .disabled(newTaskText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Tasks for day \(selectedDay)")
    }
}

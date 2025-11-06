import SwiftUI

struct BrainDumpEntryView: View {
    let task: Task
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

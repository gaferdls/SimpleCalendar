import SwiftUI

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

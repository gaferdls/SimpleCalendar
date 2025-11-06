import SwiftUI

struct PomodoroTimerView: View {
    let activeTask: Task
    var onDismiss: () -> Void

    @EnvironmentObject var viewModel: AppViewModel

    @State private var timeRemaining = 1500 // 25 minutes in seconds
    @State private var timerIsActive = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text(activeTask.text)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(timeString(from: timeRemaining))
                .font(.system(size: 80, weight: .bold, design: .monospaced))
                .padding()

            HStack(spacing: 30) {
                Button(action: {
                    timerIsActive.toggle()
                }) {
                    Text(timerIsActive ? "Pause" : "Start")
                        .font(.title2)
                        .frame(width: 120, height: 50)
                        .background(timerIsActive ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }

                Button(action: {
                    timeRemaining = 1500
                    timerIsActive = false
                }) {
                    Text("Reset")
                        .font(.title2)
                        .frame(width: 120, height: 50)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
            }

            Button("Dismiss") {
                onDismiss()
            }
            .padding(.top, 20)
        }
        .padding(30)
        .background(.thinMaterial)
        .cornerRadius(25)
        .shadow(radius: 15)
        .onReceive(timer) { _ in
            guard timerIsActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerIsActive = false
                viewModel.incrementFocusSessions()
            }
        }
    }

    private func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

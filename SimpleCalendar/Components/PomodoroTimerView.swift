//
//  PomodoroTimerView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/13/25.
//

import SwiftUI

struct PomodoroTimerView: View {
    // ADDED: Access to the shared view model.
    @EnvironmentObject var viewModel: AppViewModel
    
    var activeTask: DayEntry
    var onDismiss: () -> Void
    
    @State private var totalTime: TimeInterval = 25 * 60
    @State private var remainingTime: TimeInterval = 25 * 60
    @State private var timerIsRunning = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Focusing on:")
                .font(.headline)
            Text(activeTask.text)
                .font(.title2)
                .fontWeight(.bold)
            
            // MARK: Visual Timer Display
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                
                Circle()
                    .trim(from: 0, to: CGFloat(remainingTime / totalTime))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(timeString(from: remainingTime))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
            }
            .frame(width: 200, height: 200)
            .padding()
            
            // MARK: Timer Control Buttons
            HStack(spacing: 20) {
                Button(action: {
                    timerIsRunning.toggle()
                }) {
                    Text(timerIsRunning ? "Pause" : "Start")
                        .font(.headline)
                        .frame(width: 100, height: 50)
                        .background(timerIsRunning ? Color.yellow : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    timerIsRunning = false
                    remainingTime = totalTime
                }) {
                    Text("Reset")
                        .font(.headline)
                        .frame(width: 100, height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding(30)
        .background(.thickMaterial)
        .cornerRadius(20)
        .shadow(radius: 20)
        .onReceive(timer) { _ in
            guard timerIsRunning else { return }
            
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                // MODIFIED: When the timer finishes, increment the focus session count.
                viewModel.incrementFocusSessions()
                timerIsRunning = false
                onDismiss()
            }
        }
    }
    
    private func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.5)
            PomodoroTimerView(activeTask: DayEntry(text: "Preview Task"), onDismiss: {})
                // ADDED: The preview needs the environment object to work.
                .environmentObject(AppViewModel())
        }
    }
}

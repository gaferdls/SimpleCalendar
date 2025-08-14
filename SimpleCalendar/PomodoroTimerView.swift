//
//  PomodoroTimerView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/13/25.
//

import SwiftUI

struct PomodoroTimerView: View {
    // A new property to accept the active task and a closure for dismissal.
    var activeTask: DayEntry
    var onDismiss: () -> Void
    
    // The total time for a work session in seconds.
    @State private var totalTime: TimeInterval = 25 * 60
    // The remaining time for the current session.
    @State private var remainingTime: TimeInterval = 25 * 60
    // The state of the timer: running, paused, or stopped.
    @State private var timerIsRunning = false
    
    // A timer that fires every second.
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
                
                // Display the remaining time.
                Text(timeString(from: remainingTime))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
            }
            .frame(width: 200, height: 200)
            .padding()
            
            // MARK: Timer Control Buttons
            HStack(spacing: 20) {
                // Pause/Resume Button
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
                
                // Reset Button
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
                timerIsRunning = false
                onDismiss()
            }
        }
    }
    
    // A helper function to format the time into a string (e.g., "25:00").
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
            PomodoroTimerView(activeTask: DayEntry(text: "Preview a really long task to see how the text wrapping works"), onDismiss: {})
        }
    }
}

//
//  PomodoroTimerView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/12/25.
//

import SwiftUI

struct PomodoroTimerView: View {
    
    @State private var totalTime: TimeInterval = 25 * 60
    @State private var remainingTime: TimeInterval = 25 * 60
    @State private var timerIsRunning = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View{
        VStack(spacing: 20){
            ZStack{
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                
                Circle()
                    .trim(from: 0, to: CGFloat(remainingTime / totalTime))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(timeString(from: remainingTime))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
            }
            .frame(width: 200, height: 200)
            .padding()
            
            HStack(spacing: 20){
                Button(action: {
                    timerIsRunning.toggle()
                }){
                    Text(timerIsRunning ? "Pause" : "Start")
                        .font(.headline)
                        .frame(width:100, height: 50)
                        .background(timerIsRunning ? Color.yellow : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    timerIsRunning = false
                    remainingTime = totalTime
                }){
                    Text("Reset")
                        .font(.headline)
                        .frame(width:100, height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .onReceive(timer){ _ in
            guard timerIsRunning else { return }
            
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timerIsRunning = false
            }
        }
    }
    
    private func timeString(from time: TimeInterval) -> String{
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
    }
}

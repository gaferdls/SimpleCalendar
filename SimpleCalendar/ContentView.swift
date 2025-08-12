//
//  ContentView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentDate = Date()
    @State private var selectedDay: Int?
    
    @State private var allGoals: [String: [DayEntry]] = [:]
    
    private var calendar: Calendar{
        Calendar.current
    }
    
    private func numberOfDays(in date: Date) -> Int{
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    private func firstDayOfMonth(in date: Date) -> Int{
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return calendar.component(.weekday, from: firstDay)
    }
    
    private func headerText(for date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
            NavigationStack{
                VStack {
                    // MARK: Top Section - Calendar View
                    VStack(alignment: .leading) {
                        Text(headerText(for: currentDate))
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        HStack(spacing: 0){
                            let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                            ForEach(weekdays, id: \.self) {day in
                                Text(day)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                        Grid(horizontalSpacing: 0, verticalSpacing: 10){
                            let leadingBlanks = firstDayOfMonth(in: currentDate) - 1
                            let totalDays = numberOfDays(in: currentDate)
                            let totalCells = leadingBlanks + totalDays
                            let totalRows = (totalCells + 6 ) / 7
                            
                            ForEach(0..<totalRows, id: \.self) {row in
                                GridRow{
                                    ForEach(0..<7, id: \.self) {col in
                                        let index = row * 7 + col
                                        
                                        if index < leadingBlanks || (index - leadingBlanks + 1) > totalDays{
                                            Text("")
                                                .frame(maxWidth: .infinity)
                                        } else {
                                            let dayNumber = index - leadingBlanks + 1
                                            
                                            NavigationLink(value: dayNumber) {
                                                VStack(spacing: 4) {
                                                    Text("\(dayNumber)")
                                                        .font(.body)
                                                        .frame(width: 30, height: 30)
                                                        .background(isToday(day: dayNumber) ? Color.blue.opacity(0.8) : Color.clear)
                                                        .foregroundColor(isToday(day: dayNumber) ? .white : .black)
                                                        .clipShape(Circle())
                                                    
                                                    if hasGoal(for: dayNumber) {
                                                        Circle()
                                                            .fill(Color.blue)
                                                            .frame(width: 6, height: 6)
                                                    } else {
                                                        Circle()
                                                            .fill(Color.clear)
                                                            .frame(width: 6, height: 6)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(.plain)
                                            .tint(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Today's Focus")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.leading)
                            
                            Divider()
                            
                            Text("Brain Dump")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.leading)
                            Spacer()
                        }
                    }
                }
                .onAppear {
                    self.allGoals = DataManager.shared.load()
                }
                .navigationDestination(for: Int.self) { day in
                    DayDetailView(selectedDay: day, onGoalsUpdated: {
                        self.allGoals = DataManager.shared.load()
                        print("Goals were updated! Reloading the calendar.")
                    })
                }
                .navigationTitle("Calendar")
            }
        }
    
    func isToday(day: Int) -> Bool{
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentDate)
        
        return components.day == day && components.month == currentMonthComponents.month && components.year == currentMonthComponents.year
    }
    
    private func dateKey(for day: Int) -> String{
        let today = Date()
        var components = Calendar.current.dateComponents([.year, .month], from: today)
        components.day = day
        let selectedDate = Calendar.current.date(from: components) ?? today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private func hasGoal (for day: Int) -> Bool{
        let key = dateKey(for: day)
        return !(allGoals[key] ?? []).isEmpty
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View{
        ContentView()
    }
}

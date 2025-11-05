//
//  CalendarView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/14/25.
//

import SwiftUI

// This view has been refactored to focus solely on the monthly calendar.
struct CalendarView: View {
    
    @EnvironmentObject var viewModel: AppViewModel
    
    // UI Interaction State
    @State private var currentDate = Date()
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private func numberOfDays(in date: Date) -> Int {
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    private func firstDayOfMonth(in date: Date) -> Int {
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return calendar.component(.weekday, from: firstDay)
    }
    
    private func headerText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func changeMonth(by amount: Int) {
        if let newDate = calendar.date(byAdding: .month, value: amount, to: currentDate) {
            currentDate = newDate
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: Calendar Grid
                    VStack(alignment: .leading) {
                        HStack {
                            Text(headerText(for: currentDate))
                                .font(.title)
                                .fontWeight(.bold)

                            Spacer()

                            Button(action: {
                                changeMonth(by: -1)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                            }

                            Button(action: {
                                changeMonth(by: 1)
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 0) {
                            ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                                Text(day)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                        Grid(horizontalSpacing: 0, verticalSpacing: 10) {
                            let leadingBlanks = firstDayOfMonth(in: currentDate) - 1
                            let totalDays = numberOfDays(in: currentDate)
                            let totalCells = leadingBlanks + totalDays
                            let totalRows = (totalCells + 6 ) / 7
                            
                            ForEach(0..<totalRows, id: \.self) { row in
                                GridRow {
                                    ForEach(0..<7, id: \.self) { col in
                                        let index = row * 7 + col
                                        
                                        if index < leadingBlanks || (index - leadingBlanks + 1) > totalDays {
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
                                                        .foregroundColor(isToday(day: dayNumber) ? .white : .primary)
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
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationDestination(for: Int.self) { day in
                DayDetailView(selectedDay: day)
            }
            .navigationTitle("Calendar")
        }
    }
    
    // MARK: - Helper Functions
    
    func isToday(day: Int) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentDate)
        
        return components.day == day && components.month == currentMonthComponents.month && components.year == currentMonthComponents.year
    }
    
    private func dateKey(for day: Int) -> String {
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.day = day
        let selectedDate = Calendar.current.date(from: components) ?? currentDate
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private func hasGoal (for day: Int) -> Bool {
        let key = dateKey(for: day)
        return !(viewModel.allGoals[key] ?? []).isEmpty
    }
}


// MARK: - Helper Views for CalendarView

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

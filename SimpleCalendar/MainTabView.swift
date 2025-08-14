//
//  MainTabView.swift
//  SimpleCalendar
//
//  Created by Geanpierre Fernandez on 8/14/25.
//

import SwiftUI

struct MainTabView: View{
    var body: some View {
            TabView {
                // Tab 1: Today's Focus (The new main screen)
                // It now correctly shows our new ContentView.
                ContentView()
                    .tabItem {
                        Image(systemName: "star.fill")
                        Text("Today")
                    }

                // Tab 2: The original calendar view
                CalendarView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }

                // Tab 3: The To-Do Inbox
                Text("To-Do Inbox (Placeholder)")
                    .tabItem {
                        Image(systemName: "tray.fill")
                        Text("Inbox")
                    }
            }
        }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

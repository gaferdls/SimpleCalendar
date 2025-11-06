import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "star.fill")
                }

            BrainDumpView()
                .tabItem {
                    Label("Brain Dump", systemImage: "tray.full.fill")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            StatsView(totalCompleted: viewModel.totalTasksCompleted, currentStreak: viewModel.streakData.currentStreak)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
    }
}

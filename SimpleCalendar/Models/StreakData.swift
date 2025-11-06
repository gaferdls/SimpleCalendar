import Foundation

struct StreakData: Codable {
    var currentStreak: Int = 0
    var lastCompletionDate: Date?
}

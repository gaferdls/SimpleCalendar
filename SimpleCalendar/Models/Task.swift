import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var text: String
    var isCompleted: Bool
    var startTime: Date?
    var creationDate: Date
    var isBrainDump: Bool

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false, startTime: Date? = nil, creationDate: Date = Date(), isBrainDump: Bool) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.startTime = startTime
        self.creationDate = creationDate
        self.isBrainDump = isBrainDump
    }
}

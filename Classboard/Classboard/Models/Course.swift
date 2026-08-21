import Foundation
import SwiftData

@Model
final class Course {
    @Attribute(.unique) var id: UUID
    var name: String
    var professor: String?
    var location: String?
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var schedules: [ClassSchedule]

    init(
        id: UUID = UUID(),
        name: String,
        professor: String? = nil,
        location: String? = nil,
        colorHex: String,
        schedules: [ClassSchedule],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.professor = professor
        self.location = location
        self.colorHex = colorHex
        self.schedules = schedules
        self.createdAt = createdAt
    }
}

import Foundation

enum Weekday: Int, Codable, CaseIterable, Comparable, Identifiable, Sendable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .monday: "월요일"
        case .tuesday: "화요일"
        case .wednesday: "수요일"
        case .thursday: "목요일"
        case .friday: "금요일"
        case .saturday: "토요일"
        case .sunday: "일요일"
        }
    }

    var shortName: String {
        switch self {
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        case .sunday: "일"
        }
    }

    var isWeekend: Bool {
        self == .saturday || self == .sunday
    }

    static var weekdays: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday]
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        switch calendar.component(.weekday, from: date) {
        case 2: .monday
        case 3: .tuesday
        case 4: .wednesday
        case 5: .thursday
        case 6: .friday
        case 7: .saturday
        default: .sunday
        }
    }
}

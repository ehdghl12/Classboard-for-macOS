import SwiftUI

enum ColorHelper {
    static func color(for hex: String) -> Color {
        Color(hex: hex)
    }

    static func defaultColor(index: Int) -> String {
        AppConfiguration.defaultCourseColors[index % AppConfiguration.defaultCourseColors.count]
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = Int(cleaned, radix: 16) ?? 0x4F7DFF
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

import SwiftUI

struct TimeLabel: View {
    var start: TimeOfDay
    var end: TimeOfDay?

    var body: some View {
        if let end {
            Text("\(start.displayText) - \(end.displayText)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        } else {
            Text(start.displayText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

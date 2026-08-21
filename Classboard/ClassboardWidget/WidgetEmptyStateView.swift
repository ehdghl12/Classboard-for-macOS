import SwiftUI

struct WidgetEmptyStateView: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .lineLimit(2)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

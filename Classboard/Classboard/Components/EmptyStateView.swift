import SwiftUI

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String = "calendar"

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

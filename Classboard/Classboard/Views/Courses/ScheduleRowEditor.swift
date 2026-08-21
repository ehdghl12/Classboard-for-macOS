import SwiftUI

struct ScheduleRowEditor: View {
    @Binding var draft: ScheduleDraft
    var canDelete: Bool
    var onDelete: () -> Void

    private let minimumHour = 8
    private let maximumHour = 22

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Picker("요일", selection: $draft.weekday) {
                ForEach(Weekday.allCases) { weekday in
                    Text(weekday.displayName).tag(weekday)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 6) {
                timeControlRow(
                    label: "시작",
                    selection: Binding(
                        get: { draft.startTime },
                        set: { draft.startDate = ScheduleDraft.date(hour: $0.hour, minute: 0) }
                    )
                )

                timeControlRow(
                    label: "종료",
                    selection: Binding(
                        get: { draft.endTime },
                        set: { draft.endDate = ScheduleDraft.date(hour: $0.hour, minute: 0) }
                    )
                )
            }

            Spacer(minLength: 0)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .disabled(!canDelete)
            .help("시간 삭제")
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
    }

    private func timeControlRow(label: String, selection: Binding<TimeOfDay>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            Text(selection.wrappedValue.displayText)
                .font(.callout.monospacedDigit())
                .frame(width: 52, alignment: .trailing)

            HStack(spacing: 2) {
                Button {
                    adjustHour(by: -1, selection: selection)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(selection.wrappedValue.hour <= minimumHour)
                .help("\(label) 시간 1시간 감소")

                Button {
                    adjustHour(by: 1, selection: selection)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(selection.wrappedValue.hour >= maximumHour)
                .help("\(label) 시간 1시간 증가")
            }
            .controlSize(.small)
            .frame(width: 48, alignment: .leading)
        }
    }

    private func adjustHour(by delta: Int, selection: Binding<TimeOfDay>) {
        let nextHour = min(max(selection.wrappedValue.hour + delta, minimumHour), maximumHour)
        selection.wrappedValue = TimeOfDay(hour: nextHour, minute: 0)
    }
}

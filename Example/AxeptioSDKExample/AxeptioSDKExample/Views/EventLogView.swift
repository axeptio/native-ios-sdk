import SwiftUI

/// The SDK events recorded by `EventLog`, newest first.
///
/// One list row for the whole log: a list only renders the rows on screen, so separate rows below
/// it would be missing from the accessibility tree the simulator tests read.
struct EventLogView: View {
    let log: EventLog

    var body: some View {
        if log.entries.isEmpty {
            Text("No events yet")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8.0) {
                ForEach(log.entries) { entry in
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(entry.message)
                            .font(.callout)
                        Text(entry.date, format: .dateTime.hour().minute().second())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

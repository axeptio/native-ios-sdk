import SwiftUI

/// The SDK events recorded by `EventLog`, newest first.
struct EventLogView: View {
    let log: EventLog

    var body: some View {
        if log.entries.isEmpty {
            Text("No events yet")
                .foregroundStyle(.secondary)
        } else {
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

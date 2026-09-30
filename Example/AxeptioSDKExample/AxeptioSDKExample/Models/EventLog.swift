import AxeptioSDK
import Foundation
import Observation

/// Records what the SDK reports, to show integrators both event APIs at work:
/// `Axeptio.consentStatus` and an `AxeptioEventListener`.
@Observable
@MainActor
final class EventLog {
    struct Entry: Identifiable {
        let id = UUID()
        let date = Date()
        let message: String
    }

    private(set) var entries: [Entry] = []

    @ObservationIgnored
    private let listener = AxeptioEventListener()

    init() {
        listener.onPopupClosedEvent = { [weak self] in self?.append("Consent flow closed") }
        listener.onConsentsUpdated = { [weak self] in self?.append("Consents updated") }
        listener.onError = { [weak self] in self?.append("Error: \($0.localizedDescription)") }
    }

    /// Logs every consent status and listener callback until the calling task is cancelled.
    /// The listener is registered only meanwhile: the SDK keeps listeners until they're removed.
    func follow() async {
        Axeptio.shared.setEventListener(listener)
        defer { Axeptio.shared.removeEventListener(listener) }

        for await status in Axeptio.shared.consentStatus {
            append("Consent status: \(status)")
        }
    }

    private func append(_ message: String) {
        entries.insert(Entry(message: message), at: 0)
    }
}

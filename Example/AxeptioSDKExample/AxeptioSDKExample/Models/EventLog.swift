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

    /// Registers the listener; call it before `initialize` so its first errors are logged too,
    /// and pair it with ``stopListening()``: the SDK keeps listeners until they're removed.
    func startListening() {
        Axeptio.shared.setEventListener(listener)
    }

    func stopListening() {
        Axeptio.shared.removeEventListener(listener)
    }

    /// Logs every consent status until the calling task is cancelled.
    func followConsentStatus() async {
        for await status in Axeptio.shared.consentStatus {
            append("Consent status: \(status)")
        }
    }

    private func append(_ message: String) {
        entries.insert(Entry(message: message), at: 0)
    }
}

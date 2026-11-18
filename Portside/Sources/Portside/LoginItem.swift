import AppKit
import Observation
import os
import ServiceManagement

@MainActor
@Observable
final class LoginItem {
    private(set) var status = SMAppService.mainApp.status
    @ObservationIgnored private let log = Logger(subsystem: "no.torjusb.portside", category: "LoginItem")

    var isEnabled: Bool { status == .enabled }

    private func refresh() {
        status = SMAppService.mainApp.status
    }

    func setEnabled(_ enabled: Bool) {
        defer { refresh() }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            log.error("Could not \(enabled ? "register" : "unregister", privacy: .public) login item: \(error.localizedDescription, privacy: .public)")
            NSApplication.shared.activate()
            NSAlert(error: error).runModal()
        }
    }
}

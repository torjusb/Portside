import AppKit
import PortlessCore
import SwiftUI

struct PortsideApp: App {
    @State private var store = StateStore()
    @State private var updater = Updater()
    @State private var loginItem = LoginItem()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store, updater: updater, loginItem: loginItem)
        } label: {
            if case .proxyDown = store.snapshot {
                Image(systemName: "network.slash")
            } else {
                Image(systemName: "network")
                Text("\(store.snapshot.urls.count)")
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuContent: View {
    let store: StateStore
    let updater: Updater
    let loginItem: LoginItem

    var body: some View {
        switch store.snapshot {
        case .proxyDown:
            Text("Portless proxy is not running")
            Divider()
            Text("Start an app with: portless run <command>")
        case .noRoutes(let proxy):
            Text("No active routes")
            Divider()
            Text(statusLine(proxy))
        case .routes(let proxy, let groups):
            ForEach(groups) { group in
                Section(group.name) {
                    ForEach(group.urls) { URLItem(active: $0) }
                }
            }
            Divider()
            Text(statusLine(proxy))
            Text("Hold Option to copy a URL")
        }
        Divider()
        Text("Portside \(version)")
        if updater.isAvailable {
            Button("Check for Updates…") { updater.checkForUpdates() }
                .disabled(!updater.canCheckForUpdates)
        }
        Toggle("Launch at Login", isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) }))
        Divider()
        Button("Refresh") { store.refresh() }
            .keyboardShortcut("r")
        Button("Quit Portside") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    private func statusLine(_ proxy: ProxyState) -> String {
        "Proxy running on port \(proxy.port) (\(proxy.tls ? "HTTPS" : "HTTP"))"
    }
}

struct URLItem: View {
    let active: ActiveURL

    var body: some View {
        Button("\(active.hostname)  →  :\(String(active.targetPort))") {
            NSWorkspace.shared.open(active.url)
        }
        .modifierKeyAlternate(.option) {
            Button("Copy \(active.url.absoluteString)") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(active.url.absoluteString, forType: .string)
            }
        }
    }
}

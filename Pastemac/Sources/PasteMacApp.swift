import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct PasteMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ClipboardStore()

    var body: some Scene {
        MenuBarExtra("PasteMac", systemImage: "list.clipboard.fill") {
            ContentView(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

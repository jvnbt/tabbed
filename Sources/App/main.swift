import AppKit

// Before AppKit, configuration, permission requests, or event monitors start.
guard tabbed_apply_network_sandbox() == 0 else {
    exit(EXIT_FAILURE)
}

let app = NSApplication.shared
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let hotKeyManager = HotKeyManager()
    private let commandPanelController = CommandPanelController()

    private var statusItem: NSStatusItem?
    private var enableMenuItem: NSMenuItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.info("Application did finish launching")
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureHotKey()

        appState.onChange = { [weak self] _ in
            self?.syncMenuState()
            self?.configureHotKey()
        }

        hotKeyManager.onHotKey = { [weak self] in
            self?.showCommandPanel()
        }
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "command", accessibilityDescription: "AnyCmd")
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        menu.autoenablesItems = false

        let enableMenuItem = NSMenuItem(
            title: "Enable AnyCmd",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enableMenuItem.target = self
        menu.addItem(enableMenuItem)
        self.enableMenuItem = enableMenuItem

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit AnyCmd",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.statusItem = statusItem
        syncMenuState()
    }

    private func syncMenuState() {
        enableMenuItem?.state = appState.settings.enabled ? .on : .off
    }

    private func configureHotKey() {
        if appState.isRecordingHotkey {
            appState.hotkeyRegistrationStatus = .recording
            _ = hotKeyManager.update(enabled: false, hotkey: appState.settings.hotkey)
            AppLogger.info("Hotkey temporarily disabled while recording")
            return
        }

        appState.hotkeyRegistrationStatus = hotKeyManager.update(
            enabled: appState.settings.enabled,
            hotkey: appState.settings.hotkey
        )
        AppLogger.info("Hotkey status: \(appState.hotkeyRegistrationStatus.logMessage)")
    }

    private func showCommandPanel() {
        guard appState.settings.enabled else {
            AppLogger.info("Hotkey ignored because AnyCmd is disabled")
            return
        }

        AppLogger.info("Hotkey fired; presenting command panel with \(appState.settings.commands.count) command(s)")
        commandPanelController.present(commands: appState.settings.commands)
    }

    @objc private func toggleEnabled() {
        appState.settings.enabled.toggle()
    }

    @objc private func openSettings() {
        if let settingsWindow {
            NSApp.activate(ignoringOtherApps: true)
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsView(appState: appState))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "AnyCmd Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.minSize = NSSize(width: 760, height: 460)
        window.setContentSize(NSSize(width: 820, height: 520))
        window.center()
        window.isReleasedWhenClosed = false

        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

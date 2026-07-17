import AppKit
import Carbon
import SwiftUI

@MainActor
final class CommandPanelController {
    private var panel: CommandPanelWindow?
    private var lastPresentationDate = Date.distantPast

    func present(commands: [CommandPreset]) {
        let now = Date()
        guard now.timeIntervalSince(lastPresentationDate) > 0.25 else {
            AppLogger.info("Command panel presentation ignored by debounce")
            return
        }
        lastPresentationDate = now

        if let panel, panel.isVisible {
            AppLogger.info("Command panel already visible; refreshing content and bringing it to front")
            configure(panel: panel, commands: commands)
            NSApp.activate(ignoringOtherApps: true)
            panel.orderFrontRegardless()
            panel.makeKeyAndOrderFront(nil)
            return
        }

        show(commands: commands)
    }

    private func show(commands: [CommandPreset]) {
        let screen = screenForPanel()
        let size = panelSize(commandCount: commands.count, screen: screen)
        let origin = origin(for: size, screen: screen)
        AppLogger.info("Creating command panel at x=\(origin.x), y=\(origin.y), width=\(size.width), height=\(size.height)")

        let panel = CommandPanelWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .statusBar
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.onClose = { [weak self, weak panel] in
            guard let self, self.panel === panel else {
                return
            }
            self.panel = nil
        }
        configure(panel: panel, commands: commands, screen: screen)

        self.panel = panel

        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        AppLogger.info("Command panel ordered front; isVisible=\(panel.isVisible), frame=\(panel.frame)")
    }

    private func configure(panel: CommandPanelWindow, commands: [CommandPreset], screen: NSScreen? = nil) {
        let screen = screen ?? screenForPanel()
        let size = panelSize(commandCount: commands.count, screen: screen)
        let origin = origin(for: size, screen: screen)
        let hostingView = NSHostingView(
            rootView: CommandPickerView(commands: commands) { [weak self] command in
                Self.copyToPasteboard(command.content)
                self?.panel?.close()
                self?.panel = nil
            }
            .frame(width: size.width, height: size.height)
        )
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        AppLogger.info("Configured command panel with \(commands.count) command(s); frame=\(panel.frame), contentFrame=\(hostingView.frame)")
    }

    private func panelSize(commandCount: Int, screen: NSScreen) -> NSSize {
        let rowHeight: CGFloat = 44
        let verticalPadding: CGFloat = 28
        let emptyHeight: CGFloat = 148
        let minimumHeight: CGFloat = 120
        let maxHeight = min(420, screen.visibleFrame.height * 0.6)
        let contentHeight = commandCount == 0
            ? emptyHeight
            : min(max(CGFloat(commandCount) * rowHeight + verticalPadding, minimumHeight), maxHeight)
        return NSSize(width: 360, height: contentHeight)
    }

    private func origin(for size: NSSize, screen: NSScreen) -> NSPoint {
        let visibleFrame = screen.visibleFrame
        return NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2
        )
    }

    private func screenForPanel() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private static func copyToPasteboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
}

final class CommandPanelWindow: NSPanel {
    var onClose: (() -> Void)?
    private var isClosing = false

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            close()
            return
        }

        super.keyDown(with: event)
    }

    override func resignKey() {
        super.resignKey()

        guard !isClosing else {
            return
        }

        close()
    }

    override func close() {
        guard !isClosing else {
            return
        }

        isClosing = true
        super.close()
        onClose?()
    }
}

struct CommandPickerView: View {
    var commands: [CommandPreset]
    var onSelect: (CommandPreset) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if commands.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(commands) { command in
                            Button {
                                onSelect(command)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.on.clipboard")
                                        .foregroundStyle(.secondary)
                                    Text(command.name.isEmpty ? "Untitled Command" : command.name)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 40)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .shadow(radius: 18, y: 8)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "command")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No commands yet")
                .font(.headline)
            Text("Open Settings from the menu bar to add one.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

import AppKit
import Carbon
import SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    var hotkey: HotkeyDefinition
    var onRecord: @MainActor (HotkeyDefinition) -> Void
    var onRecordingChanged: @MainActor (Bool) -> Void

    func makeNSView(context: Context) -> HotkeyRecorderControl {
        let control = HotkeyRecorderControl()
        control.hotkey = hotkey
        control.onRecord = onRecord
        control.onRecordingChanged = onRecordingChanged
        return control
    }

    func updateNSView(_ nsView: HotkeyRecorderControl, context: Context) {
        nsView.hotkey = hotkey
        nsView.onRecord = onRecord
        nsView.onRecordingChanged = onRecordingChanged
    }
}

final class HotkeyRecorderControl: NSView {
    var hotkey: HotkeyDefinition = .optionQ {
        didSet {
            needsDisplay = true
        }
    }

    var onRecord: (@MainActor (HotkeyDefinition) -> Void)?
    var onRecordingChanged: (@MainActor (Bool) -> Void)?

    private var eventMonitor: Any?
    private var isRecording = false {
        didSet {
            guard oldValue != isRecording else {
                return
            }
            onRecordingChanged?(isRecording)
            needsDisplay = true
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 220, height: 34)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        startRecording()
        needsDisplay = true
    }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return true
    }

    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }

    override func keyDown(with event: NSEvent) {
        handleKeyDown(event)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            stopRecording()
        }
    }

    private func startRecording() {
        guard !isRecording else {
            return
        }

        isRecording = true
        installEventMonitor()
    }

    private func stopRecording() {
        isRecording = false
        removeEventMonitor()
    }

    private func handleKeyDown(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return
        }

        guard let recordedHotkey = HotkeyDefinition(event: event) else {
            NSSound.beep()
            return
        }

        hotkey = recordedHotkey
        onRecord?(recordedHotkey)
        stopRecording()
    }

    private func installEventMonitor() {
        removeEventMonitor()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isRecording else {
                return event
            }

            self.handleKeyDown(event)
            return nil
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor.controlBackgroundColor.setFill()
        path.fill()

        let strokeColor = isRecording
            ? NSColor.controlAccentColor
            : NSColor.separatorColor
        strokeColor.setStroke()
        path.lineWidth = isRecording ? 2 : 1
        path.stroke()

        let title = isRecording
            ? "Press shortcut"
            : hotkey.displayString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        let titleSize = attributedTitle.size()
        let titleRect = NSRect(
            x: (bounds.width - titleSize.width) / 2,
            y: (bounds.height - titleSize.height) / 2,
            width: titleSize.width,
            height: titleSize.height
        )
        attributedTitle.draw(in: titleRect)
    }
}

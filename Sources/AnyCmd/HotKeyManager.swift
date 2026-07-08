import AppKit
import Carbon
import Foundation

final class HotKeyManager: @unchecked Sendable {
    var onHotKey: (@MainActor () -> Void)?

    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var registeredHotkey: HotkeyDefinition?

    deinit {
        unregister()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func update(enabled: Bool, hotkey: HotkeyDefinition) -> HotKeyRegistrationStatus {
        guard enabled else {
            unregister()
            return .disabled
        }

        guard registeredHotkey != hotkey else {
            return .registered(hotkey)
        }

        unregister()
        return register(hotkey)
    }

    private func register(_ hotkey: HotkeyDefinition) -> HotKeyRegistrationStatus {
        guard installEventHandlerIfNeeded() == noErr else {
            return .handlerUnavailable
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.fourCharCode("ACMD"),
            id: 1
        )
        var newHotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &newHotKeyRef
        )

        guard status == noErr else {
            AppLogger.error("Failed to register hotkey \(hotkey.displayString): \(status)")
            registeredHotkey = nil
            return .failed(hotkey, status)
        }

        hotKeyRef = newHotKeyRef
        registeredHotkey = hotkey
        AppLogger.info("Registered hotkey \(hotkey.displayString)")
        return .registered(hotkey)
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            AppLogger.info("Unregistered hotkey")
        }
        hotKeyRef = nil
        registeredHotkey = nil
    }

    @discardableResult
    private func installEventHandlerIfNeeded() -> OSStatus {
        if eventHandlerRef != nil {
            return noErr
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else {
                return noErr
            }

            let manager = Unmanaged<HotKeyManager>
                .fromOpaque(userData)
                .takeUnretainedValue()

            Task { @MainActor in
                manager.onHotKey?()
            }

            return noErr
        }

        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )
        if status == noErr {
            AppLogger.info("Installed hotkey event handler")
        } else {
            AppLogger.error("Failed to install hotkey event handler: \(status)")
        }
        return status
    }

    private static func fourCharCode(_ string: String) -> OSType {
        var result: UInt32 = 0
        for scalar in string.unicodeScalars.prefix(4) {
            result = (result << 8) + scalar.value
        }
        return result
    }
}

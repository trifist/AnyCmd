import Foundation

enum HotKeyRegistrationStatus: Equatable {
    case disabled
    case recording
    case handlerUnavailable
    case registered(HotkeyDefinition)
    case failed(HotkeyDefinition, OSStatus)

    var message: String {
        switch self {
        case .disabled:
            return "Shortcut is disabled."
        case .recording:
            return "Recording shortcut..."
        case .handlerUnavailable:
            return "Failed to install macOS hotkey handler."
        case .registered(let hotkey):
            return "Registered: \(hotkey.displayString)"
        case .failed(let hotkey, let status):
            return "Failed to register \(hotkey.displayString). macOS returned \(status). Try another shortcut."
        }
    }

    var logMessage: String {
        switch self {
        case .disabled:
            return "disabled"
        case .recording:
            return "recording"
        case .handlerUnavailable:
            return "handler unavailable"
        case .registered(let hotkey):
            return "registered \(hotkey.displayString)"
        case .failed(let hotkey, let status):
            return "failed \(hotkey.displayString), status \(status)"
        }
    }
}

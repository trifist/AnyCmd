import AppKit
import Carbon
import Foundation

struct CommandPreset: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var content: String

    init(id: UUID = UUID(), name: String, content: String) {
        self.id = id
        self.name = name
        self.content = content
    }
}

struct AppSettings: Codable, Equatable, Sendable {
    var enabled: Bool
    var hotkey: HotkeyDefinition
    var commands: [CommandPreset]

    static let `default` = AppSettings(
        enabled: true,
        hotkey: .optionQ,
        commands: []
    )
}

struct HotkeyDefinition: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let optionQ = HotkeyDefinition(
        keyCode: UInt32(kVK_ANSI_Q),
        modifiers: UInt32(optionKey)
    )

    static let legacyOptionC = HotkeyDefinition(
        keyCode: UInt32(kVK_ANSI_C),
        modifiers: UInt32(optionKey)
    )

    var displayString: String {
        let parts = modifierDisplayParts + [Self.keyName(for: keyCode)]
        return parts.joined(separator: " + ")
    }

    private var modifierDisplayParts: [String] {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("Command")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("Control")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("Option")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("Shift")
        }
        return parts
    }

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        let mappedModifiers = Self.carbonModifiers(from: event.modifierFlags)
        guard mappedModifiers != 0 else {
            return nil
        }

        self.keyCode = UInt32(event.keyCode)
        self.modifiers = mappedModifiers
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        let flags = flags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        return modifiers
    }

    static func keyName(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: "A"
        case kVK_ANSI_B: "B"
        case kVK_ANSI_C: "C"
        case kVK_ANSI_D: "D"
        case kVK_ANSI_E: "E"
        case kVK_ANSI_F: "F"
        case kVK_ANSI_G: "G"
        case kVK_ANSI_H: "H"
        case kVK_ANSI_I: "I"
        case kVK_ANSI_J: "J"
        case kVK_ANSI_K: "K"
        case kVK_ANSI_L: "L"
        case kVK_ANSI_M: "M"
        case kVK_ANSI_N: "N"
        case kVK_ANSI_O: "O"
        case kVK_ANSI_P: "P"
        case kVK_ANSI_Q: "Q"
        case kVK_ANSI_R: "R"
        case kVK_ANSI_S: "S"
        case kVK_ANSI_T: "T"
        case kVK_ANSI_U: "U"
        case kVK_ANSI_V: "V"
        case kVK_ANSI_W: "W"
        case kVK_ANSI_X: "X"
        case kVK_ANSI_Y: "Y"
        case kVK_ANSI_Z: "Z"
        case kVK_ANSI_0: "0"
        case kVK_ANSI_1: "1"
        case kVK_ANSI_2: "2"
        case kVK_ANSI_3: "3"
        case kVK_ANSI_4: "4"
        case kVK_ANSI_5: "5"
        case kVK_ANSI_6: "6"
        case kVK_ANSI_7: "7"
        case kVK_ANSI_8: "8"
        case kVK_ANSI_9: "9"
        case kVK_Space: "Space"
        case kVK_Return: "Return"
        case kVK_Escape: "Escape"
        case kVK_Tab: "Tab"
        case kVK_Delete: "Delete"
        case kVK_LeftArrow: "Left"
        case kVK_RightArrow: "Right"
        case kVK_UpArrow: "Up"
        case kVK_DownArrow: "Down"
        default: "Key \(keyCode)"
        }
    }
}

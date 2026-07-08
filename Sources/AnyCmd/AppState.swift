import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    private static let settingsKey = "AnyCmd.settings.v1"

    @Published var isRecordingHotkey = false {
        didSet {
            onChange?(settings)
        }
    }

    @Published var hotkeyRegistrationStatus: HotKeyRegistrationStatus = .disabled

    @Published var settings: AppSettings {
        didSet {
            save()
            onChange?(settings)
        }
    }

    var onChange: ((AppSettings) -> Void)?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if
            let data = userDefaults.data(forKey: Self.settingsKey),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            self.settings = Self.migratedSettings(decoded)
        } else {
            self.settings = .default
        }
    }

    func addCommand() -> UUID {
        let command = CommandPreset(name: nextCommandName(), content: "")
        settings.commands.append(command)
        return command.id
    }

    func deleteCommand(id: UUID) {
        settings.commands.removeAll { $0.id == id }
    }

    func command(id: UUID) -> CommandPreset? {
        settings.commands.first { $0.id == id }
    }

    func updateCommandName(id: UUID, name: String) {
        guard let index = settings.commands.firstIndex(where: { $0.id == id }) else {
            return
        }
        settings.commands[index].name = name
    }

    func updateCommandContent(id: UUID, content: String) {
        guard let index = settings.commands.firstIndex(where: { $0.id == id }) else {
            return
        }
        settings.commands[index].content = content
    }

    private let userDefaults: UserDefaults

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        userDefaults.set(data, forKey: Self.settingsKey)
    }

    private static func migratedSettings(_ settings: AppSettings) -> AppSettings {
        guard settings.hotkey == .legacyOptionC else {
            return settings
        }

        var migratedSettings = settings
        migratedSettings.hotkey = .optionQ
        return migratedSettings
    }

    private func nextCommandName() -> String {
        let baseName = "New Command"
        let existingNames = Set(settings.commands.map(\.name))
        guard existingNames.contains(baseName) else {
            return baseName
        }

        var index = 2
        while existingNames.contains("\(baseName) \(index)") {
            index += 1
        }
        return "\(baseName) \(index)"
    }
}

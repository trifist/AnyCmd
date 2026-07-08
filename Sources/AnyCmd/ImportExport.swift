import Foundation

struct AnyCmdExportFile: Codable {
    var app: String
    var version: Int
    var exportedAt: Date
    var settings: AppSettings

    static let currentVersion = 1

    init(settings: AppSettings, exportedAt: Date = Date()) {
        self.app = "AnyCmd"
        self.version = Self.currentVersion
        self.exportedAt = exportedAt
        self.settings = settings
    }
}

enum ImportExportError: LocalizedError {
    case unsupportedFile

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            return "The selected file is not a supported AnyCmd export."
        }
    }
}

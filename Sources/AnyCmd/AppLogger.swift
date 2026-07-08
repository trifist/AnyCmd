import Foundation

enum AppLogger {
#if ANYCMD_ENABLE_LOGGING
    static var logURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/AnyCmd.log")
    }
#endif

    @inline(__always)
    static func info(_ message: @autoclosure () -> String) {
#if ANYCMD_ENABLE_LOGGING
        write("INFO", message())
#endif
    }

    @inline(__always)
    static func error(_ message: @autoclosure () -> String) {
#if ANYCMD_ENABLE_LOGGING
        write("ERROR", message())
#endif
    }

#if ANYCMD_ENABLE_LOGGING
    private static func write(_ level: String, _ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"

        NSLog("AnyCmd \(level): \(message)")

        do {
            let url = logURL
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            guard let data = line.data(using: .utf8) else {
                return
            }

            if FileManager.default.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: url)
            }
        } catch {
            NSLog("AnyCmd ERROR: Failed to write log: \(error.localizedDescription)")
        }
    }
#endif
}

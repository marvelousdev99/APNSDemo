import Foundation
import Logging

struct FileLogHandler: LogHandler {
    private let fileHandle: FileHandle
    var logLevel: Logger.Level = .info
    var metadata: Logger.Metadata = [:]

    init(fileURL: URL) {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        self.fileHandle = try! FileHandle(forWritingTo: fileURL)
        self.fileHandle.seekToEndOfFile()
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?,
             source: String, file: String, function: String, line: UInt) {
        let line = "[\(level)] \(message)\n"
        if let data = line.data(using: .utf8) {
            fileHandle.write(data)
        }
    }
}

enum LoggerFactory {
    static func make() -> Logger {
        let logDirectory: URL
        if getuid() == 0 {
            logDirectory = URL(fileURLWithPath: "/var/log/IDMNotification")
        } else {
            logDirectory = FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Logs/IDMNotification")
        }

        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        let logFileURL = logDirectory.appendingPathComponent("app.log")

        // Bootstrap with file + console
        LoggingSystem.bootstrap { label in
            MultiplexLogHandler([
                FileLogHandler(fileURL: logFileURL),
                StreamLogHandler.standardOutput(label: label)
            ])
        }

        let logger = Logger(label: "com.idemeum.daemon")
        logger.info("Logger initialized at \(logFileURL.path)")
        return logger
    }
}


import Foundation
import XCGLogger

class SdkLogListener : Logger {
    private var logger: XCGLogger

    init(logger: XCGLogger) {
        self.logger = logger
    }

    func log(l: LogEntry) {
        // Extract tag from log line if present (format: "message [mem: X.XMB]")
        // The tag is passed via ServiceLogger and included in the line
        let line = l.line

        switch(l.level) {
        case "ERROR":
            logger.logln(line, level: .error, functionName: "", fileName: "BreezSDK", lineNumber: 0)
        case "WARN":
            logger.logln(line, level: .warning, functionName: "", fileName: "BreezSDK", lineNumber: 0)
        case "INFO":
            logger.logln(line, level: .info, functionName: "", fileName: "BreezSDK", lineNumber: 0)
        case "DEBUG":
            logger.logln(line, level: .debug, functionName: "", fileName: "BreezSDK", lineNumber: 0)
        case "TRACE":
            logger.logln(line, level: .verbose, functionName: "", fileName: "BreezSDK", lineNumber: 0)
        default:
            return
        }
    }
}

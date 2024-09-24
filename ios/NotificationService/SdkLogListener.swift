import Foundation
import XCGLogger

class SdkLogListener : Logger {
    private var logger: XCGLogger
    
    init(logger: XCGLogger) {
        self.logger = logger
    }
    
    func log(l: LogEntry) {
        switch(l.level) {
        case "ERROR":
            logger.error { l.line }
            break
        case "WARN":
            logger.warning { l.line }
            break
        case "INFO":
            logger.info { l.line }
            break
        case "DEBUG":
            logger.debug { l.line }
            break
        case "TRACE":
            logger.verbose { l.line }
            break
        default:
            return
        }
    }
}

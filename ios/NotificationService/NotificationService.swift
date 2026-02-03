import UserNotifications
import XCGLogger

let accessGroup = "group.F7R2LZH3W5.com.breez.misty"

class NotificationService: SDKNotificationService {
    fileprivate let TAG = "NotificationService"

    private let accountMnemonic: String = "account_mnemonic"
    private let accountApiKey: String = "account_api_key"
    private let initTime: Date
    private var didReceiveTime: Date?
    private var xcgLogger: XCGLogger?

    override init() {
        self.initTime = Date()

        let logsDir = FileManager
            .default.containerURL(forSecurityApplicationGroupIdentifier: accessGroup)!.appendingPathComponent("logs")
        let extensionLogFile = logsDir.appendingPathComponent("\(Date().timeIntervalSince1970).ios-extension.log")
        let logger: XCGLogger = {
            let log = XCGLogger.default
            log.setup(level: .info, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: extensionLogFile.path)
            return log
        }()
        self.xcgLogger = logger

        super.init()

        // Set Notification Service Logger to SdkLogListener that utilizes XCGLogger library
        let sdkLogger = SdkLogListener(logger: logger)
        self.setServiceLogger(logger: sdkLogger)
        // Use the same SdkLogListener to listen in on BreezSDKLiquid node logs
        do {
            try setLogger(logger: sdkLogger)
        } catch let e {
            self.logger.log(tag: TAG, line:"Failed to set log stream: \(e)", level: "ERROR")
        }

        self.logger.log(tag: TAG, line: "NSE init() completed - memory: \(self.memoryUsageString())", level: "DEBUG")
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.didReceiveTime = Date()
        let timeSinceInit = self.didReceiveTime!.timeIntervalSince(self.initTime)

        self.logger.log(tag: TAG, line: "didReceive() called - timeSinceInit: \(String(format: "%.3f", timeSinceInit))s, memory: \(self.memoryUsageString())", level: "DEBUG")
        self.logger.log(tag: TAG, line: "Notification identifier: \(request.identifier)", level: "DEBUG")
        self.logger.log(tag: TAG, line: "Notification userInfo keys: \(request.content.userInfo.keys)", level: "DEBUG")

        super.didReceive(request, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
        let now = Date()
        let timeSinceInit = now.timeIntervalSince(self.initTime)
        let timeSinceDidReceive = self.didReceiveTime.map { now.timeIntervalSince($0) } ?? -1

        self.logger.log(tag: TAG, line: "serviceExtensionTimeWillExpire() called - timeSinceInit: \(String(format: "%.3f", timeSinceInit))s, timeSinceDidReceive: \(String(format: "%.3f", timeSinceDidReceive))s, memory: \(self.memoryUsageString())", level: "WARN")

        super.serviceExtensionTimeWillExpire()

        // Close logger file handle to allow iOS to terminate the process
        cleanupLogger()
    }

    /// Closes the XCGLogger file destination to release file handles
    /// This allows iOS to properly terminate the NSE process
    private func cleanupLogger() {
        if let fileDestination = xcgLogger?.destination(withIdentifier: XCGLogger.Constants.fileDestinationIdentifier) as? FileDestination {
            fileDestination.owner = nil  // This triggers closeFile()
        }
        xcgLogger?.remove(destinationWithIdentifier: XCGLogger.Constants.fileDestinationIdentifier)
    }

    override func getConnectRequest() -> ConnectRequest? {
        let startTime = Date()
        self.logger.log(tag: TAG, line: "getConnectRequest() started - memory: \(self.memoryUsageString())", level: "DEBUG")

        guard let apiKey = KeychainHelper.shared.getFlutterString(accessGroup: accessGroup, key: accountApiKey) else {
            self.logger.log(tag: TAG, line: "API key not found in keychain", level: "ERROR")
            return nil
        }
        self.logger.log(tag: TAG, line: "API key retrieved from keychain", level: "DEBUG")
        self.logger.log(tag: TAG, line: "API_KEY: \(apiKey)", level: "TRACE")

        var config: Config
        do {
            config = try defaultConfig(network: LiquidNetwork.mainnet, breezApiKey: apiKey)
            self.logger.log(tag: TAG, line: "Default config created successfully", level: "DEBUG")
        } catch {
            self.logger.log(tag: TAG, line: "Failed to get default config: \(error)", level: "ERROR")
            return nil
        }

        config.workingDir = FileManager
            .default.containerURL(forSecurityApplicationGroupIdentifier: accessGroup)!
            .path
        self.logger.log(tag: TAG, line: "Working directory: \(config.workingDir)", level: "DEBUG")

        // Disable realtime sync in NSE to reduce memory usage and background tasks
        config.syncServiceUrl = nil

        guard let mnemonic = KeychainHelper.shared.getFlutterString(accessGroup: accessGroup, key: accountMnemonic) else {
            self.logger.log(tag: TAG, line: "Mnemonic not found in keychain", level: "ERROR")
            return nil
        }
        self.logger.log(tag: TAG, line: "Mnemonic retrieved from keychain", level: "DEBUG")

        let elapsed = Date().timeIntervalSince(startTime)
        self.logger.log(tag: TAG, line: "getConnectRequest() completed in \(String(format: "%.3f", elapsed))s - memory: \(self.memoryUsageString())", level: "DEBUG")

        return ConnectRequest(config: config, mnemonic: mnemonic)
    }

    private func memoryUsageString() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / (1024 * 1024)
            return String(format: "%.1fMB", usedMB)
        }
        return "unknown"
    }
}

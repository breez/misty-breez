import UserNotifications
import XCGLogger

let accessGroup = "group.F7R2LZH3W5.com.breez.misty"

class NotificationService: SDKNotificationService {
    fileprivate let TAG = "NotificationService"

    private let accountMnemonic: String = "account_mnemonic"
    private let accountApiKey: String = "account_api_key"

    override init() {
        let logsDir = FileManager
            .default.containerURL(forSecurityApplicationGroupIdentifier: accessGroup)!.appendingPathComponent("logs")
        let extensionLogFile = logsDir.appendingPathComponent("\(Date().timeIntervalSince1970).ios-extension.log")
        let logger: XCGLogger = {
            let log = XCGLogger.default
            log.setup(level: .info, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: extensionLogFile.path)
            return log
        }()

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
    }

    override func getConnectRequest() -> ConnectRequest? {
        guard let apiKey = KeychainHelper.shared.getFlutterString(accessGroup: accessGroup, key: accountApiKey) else {
            self.logger.log(tag: TAG, line: "API key not found in keychain", level: "ERROR")
            return nil
        }

        var config: Config
        do {
            config = try defaultConfig(network: LiquidNetwork.mainnet, breezApiKey: apiKey)
        } catch {
            self.logger.log(tag: TAG, line: "Failed to get default config: \(error)", level: "ERROR")
            return nil
        }

        config.workingDir = FileManager
            .default.containerURL(forSecurityApplicationGroupIdentifier: accessGroup)!
            .path

        // Disable realtime sync in NSE to reduce memory usage and background tasks
        config.syncServiceUrl = nil

        guard let mnemonic = KeychainHelper.shared.getFlutterString(accessGroup: accessGroup, key: accountMnemonic) else {
            self.logger.log(tag: TAG, line: "Mnemonic not found in keychain", level: "ERROR")
            return nil
        }

        return ConnectRequest(config: config, mnemonic: mnemonic)
    }
}

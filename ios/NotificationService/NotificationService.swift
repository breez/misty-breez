import UserNotifications
import XCGLogger
import BreezSDKLiquid

let accessGroup = "group.F7R2LZH3W5.com.breez.liquid.lBreez"

class NotificationService: SDKNotificationService {
    fileprivate let TAG = "NotificationService"
    
    private let accountMnemonic: String = "account_mnemonic"
        
    override init(logger: Logger) {
        super.init(logger: logger)
    }
    
    convenience init() {
        let logsDir = FileManager
            .default.containerURL(forSecurityApplicationGroupIdentifier: accessGroup)!.appendingPathComponent("logs")
        let extensionLogFile = logsDir.appendingPathComponent("\(Date().timeIntervalSince1970).ios-extension.log")
        let xcgLogger: XCGLogger = {
            let log = XCGLogger.default
            log.setup(level: .info, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: extensionLogFile.path)
            return log
        }()
        
        // Set Notification Service Logger to SdkLogListener that utilizes XCGLogger library
        let sdkLogger = SdkLogListener(logger: xcgLogger)
                
        self.init(logger: sdkLogger)
    }
    
    override func getConnectRequest() -> ConnectRequest? {
        var config = defaultConfig(network: LiquidNetwork.mainnet)
        config.workingDir = FileManager
            .default.containerURL(forSecurityApplicationGroupIdentifier: accessGroup)!
            .absoluteString
        
        // Construct the ConnectRequest 
        guard let mnemonic = KeychainHelper.shared.getFlutterString(accessGroup: accessGroup, key: accountMnemonic) else {
            self.logger.log(tag: TAG, line: "Mnemonic not found", level: "ERROR")
            return nil
        }
        return ConnectRequest(config: config, mnemonic: mnemonic)
    }
}

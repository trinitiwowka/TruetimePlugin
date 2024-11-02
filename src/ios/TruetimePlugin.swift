import TrueTime

@objc(TruetimePlugin) class TruetimePlugin : CDVPlugin {
    @objc(getTime:)
    func getTime(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        let client = TrueTimeClient.sharedInstance
        let ntpUrl = command.arguments?[0] as? String

        if ntpUrl?.isEmpty ?? true {
            print("Invalid ntp url, value of ntp url passed:", ntpUrl ?? "nil")
            return
        }

        let urlString = ntpUrl ?? "pool.ntp.org"
        client.start(pool: [urlString])

        client.fetchIfNeeded { result in
            switch result {
            case let .success(referenceTime):
                let now = referenceTime.now()
                let offset = referenceTime.timeInterval()
                let uptimeInterval = referenceTime.uptimeInterval()

                let timestamp = now.timeIntervalSince1970 + offset

                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [
                    "callback": timestamp,
                    "offset": offset,
                    "uptimeInterval": uptimeInterval
                ])

                DispatchQueue.main.async {
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                }

            case let .failure(error):
                print("Error! \(error)")
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)

                DispatchQueue.main.async {
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                }
            }
        }
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0))
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

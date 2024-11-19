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

        client.fetchIfNeeded(completion:  { result in
            switch result {
            case let .success(referenceTime):
                let ntpDate = referenceTime.now()
                let systemDate = Date()

                let offset = ntpDate.timeIntervalSince(systemDate)

                let timestamp = ntpDate.timeIntervalSince1970 * 1000

                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [
                    "callback": timestamp,
                    "offset": offset * 1000
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
        })
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

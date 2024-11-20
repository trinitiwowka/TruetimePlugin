import TrueTime

@objc(TruetimePlugin) class TruetimePlugin: CDVPlugin {
    private var isClientStarted = false

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

        // Start the NTP client if not already started
        if !isClientStarted {
            client.start(pool: [urlString])
            isClientStarted = true
        }

        // Record local time before the request (T0)
        let t0 = Date().timeIntervalSince1970 * 1000

        client.fetchIfNeeded(completion: { result in
            switch result {
            case let .success(referenceTime):
                // Server time (used for T1 and T2)
                let serverTime = referenceTime.now().timeIntervalSince1970 * 1000

                // Record local time after the response (T3)
                let t3 = Date().timeIntervalSince1970 * 1000

                // Calculate the delay
                let delay = (t3 - t0) / 2

                // Construct the result
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [
                    "callback": serverTime,
                    "t0": t0,
                    "t1": serverTime,
                    "t2": serverTime,
                    "t3": t3,
                    "delay": delay
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

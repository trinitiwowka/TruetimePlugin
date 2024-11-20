import TrueTime

@objc(TruetimePlugin) class TruetimePlugin: CDVPlugin {
    private var isClientStarted = false // Флаг для отслеживания состояния клиента

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

        // Проверяем, был ли клиент уже запущен
        if !isClientStarted {
            client.start(pool: [urlString])
            isClientStarted = true
        }

        client.fetchIfNeeded(completion: { result in
            switch result {
            case let .success(referenceTime):
                let serverTime = referenceTime.now()
                let localTime = Date()
                let offset = serverTime.timeIntervalSince(localTime)
                let timestamp = serverTime.millisecondsSince1970

                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [
                    "timestamp": timestamp,
                    "offset": offset,
                    "localTime": localTime.millisecondsSince1970,
                    "serverTime": serverTime.millisecondsSince1970
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

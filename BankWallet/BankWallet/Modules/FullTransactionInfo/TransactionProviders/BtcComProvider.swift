import ObjectMapper

class BtcComBitcoinProvider: IBitcoinForksProvider {
    let name = "Btc.com"

    func url(for hash: String) -> String? {
        return "https://btc.com/" + hash 
    }

    func reachabilityUrl(for hash: String) -> String {
        return "https://chain.api.btc.com/v3/tx/" + hash 
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        return .get(url: "https://chain.api.btc.com/v3/tx/" + hash, params: nil)
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? BtcComBitcoinResponse(JSONObject: json)
    }

}

class BtcComBitcoinCashProvider: IBitcoinForksProvider {
    let name = "Btc.com"

    func url(for hash: String) -> String? {
        return "https://bch.btc.com/" + hash 
    }

    func reachabilityUrl(for hash: String) -> String {
        return "https://bch-chain.api.btc.com/v3/tx/" + hash 
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        return .get(url: "https://bch-chain.api.btc.com/v3/tx/" + hash, params: nil)
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? BtcComBitcoinResponse(JSONObject: json)
    }

}

class BtcComBitcoinResponse: IBitcoinResponse, ImmutableMappable {
    var txId: String?
    var blockTime: Int?
    var blockHeight: Int?
    var confirmations: Int?

    var size: Int?
    var fee: Decimal?
    var feePerByte: Decimal?

    var inputs = [(value: Decimal, address: String?)]()
    var outputs = [(value: Decimal, address: String?)]()

    required init(map: Map) throws {
        txId = try? map.value("data.hash")
        blockTime = try? map.value("data.block_time")
        blockHeight = try? map.value("data.block_height")
        confirmations = try? map.value("data.confirmations")

        if let fee: Double = try? map.value("data.fee"), let size: Int = try? map.value("data.size") {
            self.fee = Decimal(fee) / btcRate
            self.size = size
            feePerByte = Decimal(fee) / Decimal(size)
        }
        if let vInputs: [[String: Any]] = try? map.value("data.inputs") {
            vInputs.forEach { input in
                if let value = input["prev_value"] as? Double {
                    let address = (input["prev_addresses"] as? [String])?.first

                    inputs.append((value: Decimal(value) / btcRate, address: address))
                }
            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("data.outputs") {
            vOutputs.forEach { output in
                if let value = output["value"] as? Double {
                    let address = (output["addresses"] as? [String])?.first

                    outputs.append((value: Decimal(value) / btcRate, address: address))
                }
            }
        }
    }

}

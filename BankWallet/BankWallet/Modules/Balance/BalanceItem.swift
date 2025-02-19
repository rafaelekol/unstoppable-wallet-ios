import Foundation
import DeepDiff
import XRatesKit

class BalanceItem {
    let wallet: Wallet

    var balance: Decimal?
    var balanceLocked: Decimal?
    var state: AdapterState?
    var marketInfo: MarketInfo?
    var chartInfoState: ChartInfoState = .loading

    var balanceTotal: Decimal? {
        guard let balance = balance else {
            return nil
        }

        return balance + (balanceLocked ?? 0)
    }

    init(wallet: Wallet) {
        self.wallet = wallet
    }

}

import Foundation
import ActionSheet

class TransactionAmountItem: BaseActionItem {

    let primaryAmountInfo: AmountInfo
    var secondaryAmountInfo: AmountInfo?
    let sentToSelf: Bool
    let incoming: Bool
    let locked: Bool

    var customPrimaryFractionPolicy: ValueFormatter.FractionPolicy?

    init(item: TransactionViewItem, tag: Int? = nil) {
        if let currencyValue = item.currencyValue {
            primaryAmountInfo = .currencyValue(currencyValue: currencyValue)
            secondaryAmountInfo = .coinValue(coinValue: item.coinValue)

            customPrimaryFractionPolicy = .threshold(high: 1000, low: 0.01)
        } else {
            primaryAmountInfo = .coinValue(coinValue: item.coinValue)
        }

        sentToSelf = item.sentToSelf
        incoming = item.incoming

        locked = item.lockInfo != nil

        super.init(cellType: TransactionAmountItemView.self, tag: tag, required: true)

        height = 72
    }

}

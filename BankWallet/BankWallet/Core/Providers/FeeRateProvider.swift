import FeeRateKit
import RxSwift

class FeeRateProvider {
    private let feeRateKit: FeeRateKit

    init(appConfigProvider: IAppConfigProvider) {
        let providerConfig = FeeProviderConfig(infuraProjectId: appConfigProvider.infuraCredentials.id,
                infuraProjectSecret: appConfigProvider.infuraCredentials.secret,
                btcCoreRpcUrl: appConfigProvider.btcCoreRpcUrl,
                btcCoreRpcUser: nil,
                btcCoreRpcPassword: nil
        )
        feeRateKit = FeeRateKit.instance(providerConfig: providerConfig, minLogLevel: .error)
    }

    // Fee rates

    func ethereumGasPrice(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateKit.ethereum.map { FeeRateData(feeRate: $0) }
    }

    func bitcoinFeeRate(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateKit.bitcoin.map { FeeRateData(feeRate: $0) }
    }

    func bitcoinCashFeeRate(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateKit.bitcoinCash.map { FeeRateData(feeRate: $0) }
    }

    func dashFeeRate(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateKit.dash.map { FeeRateData(feeRate: $0) }
    }

}

class BitcoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateProvider.bitcoinFeeRate(for: priority)
    }

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateProvider.bitcoinCashFeeRate(for: priority)
    }

}

class EthereumFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateProvider.ethereumGasPrice(for: priority)
    }

}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRateData> {
        feeRateProvider.dashFeeRate(for: priority)
    }

}

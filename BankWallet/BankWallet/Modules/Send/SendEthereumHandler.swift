import Foundation
import RxSwift
import EthereumKit
import Erc20Kit

enum FeeState {
    static let zero: FeeState = .value(0)

    case loading
    case value(Int)
    case error(Error)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

}

class SendEthereumHandler {
    private var gasDisposeBag = DisposeBag()
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendEthereumInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feePriorityModule: ISendFeePriorityModule

    private var estimateGasLimitState: FeeState = .value(0)

    init(interactor: ISendEthereumInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule, feePriorityModule: ISendFeePriorityModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
        self.feePriorityModule = feePriorityModule
    }

    private func syncValidation() {
        do {
            _ = try amountModule.validAmount()
            try addressModule.validateAddress()

            delegate?.onChange(isValid: feeModule.isValid)
        } catch {
            delegate?.onChange(isValid: false)
        }
    }

    private func syncFee() {
        if feePriorityModule.feeRateState.isLoading || estimateGasLimitState.isLoading {
            amountModule.set(loading: true)
            feeModule.set(loading: true)
            return
        }
        amountModule.set(loading: false)
        feeModule.set(loading: false)

        if case let .error(error) = feePriorityModule.feeRateState {
            // show primary error from feeRateKit
            return
        } else if case let .error(error) = estimateGasLimitState {
            // show secondary error from ethereum kit
        } else if case let .value(feeRateValue) = feePriorityModule.feeRateState, case let .value(estimateGasLimitValue) = estimateGasLimitState {
            amountModule.set(availableBalance: interactor.availableBalance(gasPrice: feeRateValue, gasLimit: estimateGasLimitValue))
            feeModule.set(fee: interactor.fee(gasPrice: feeRateValue, gasLimit: estimateGasLimitValue))
        }
    }

    private func syncEstimateGasLimit() {
        guard let address = addressModule.currentAddress else {
            onReceive(gasLimit: 0)
            return
        }
        gasDisposeBag = DisposeBag()

        estimateGasLimitState = .loading
        syncFee()
        syncValidation()

        interactor.estimateGasLimit(to: address, value: amountModule.currentAmount, gasPrice: feePriorityModule.feeRate)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: onReceive, onError: onGasLimitError)
                .disposed(by: gasDisposeBag)
    }

}

extension SendEthereumHandler: ISendHandler {

    func onViewDidLoad() {
        feePriorityModule.fetchFeeRate()

        amountModule.set(minimumRequiredBalance: interactor.minimumRequiredBalance)

        feeModule.set(availableFeeBalance: interactor.ethereumBalance)
        syncFee()

        syncEstimateGasLimit()
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress()),
            SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo),
            SendConfirmationDurationViewItem(timeInterval: feePriorityModule.duration)
        ]
    }

    func sendSingle() throws -> Single<Void> {
        guard let feeRate = feePriorityModule.feeRate, case let .value(gasLimit) = estimateGasLimitState else {
            throw SendTransactionError.unknown
        }
        return interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress(), gasPrice: feeRate, gasLimit: gasLimit)
    }

}

extension SendEthereumHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
        syncEstimateGasLimit()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendEthereumHandler: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(address: address)
    }

    func onUpdateAddress() {
        syncValidation()
        syncEstimateGasLimit()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}

extension SendEthereumHandler: ISendFeeDelegate {

    var inputType: SendInputType {
        amountModule.inputType
    }

}

extension SendEthereumHandler: ISendFeePriorityDelegate {

    func onUpdateFeePriority() {
        syncFee()
        syncValidation()
        syncEstimateGasLimit()
    }

}

extension SendEthereumHandler {

    func onReceive(gasLimit: Int) {
        estimateGasLimitState = .value(gasLimit)

        syncFee()
        syncValidation()
    }

    func onGasLimitError(_ error: Error) {
        estimateGasLimitState = .error(error)

        syncFee()
        syncValidation()
    }

}
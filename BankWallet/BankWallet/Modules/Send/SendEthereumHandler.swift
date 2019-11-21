import Foundation
import RxSwift
import EthereumKit
import FeeRateKit
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

    var isValid: Bool {
        if case .value(_) = self {
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
    private let feePriorityModule: ISendFeePriorityModule
    private let feeModule: ISendFeeModule

    private var estimateGasLimitState: FeeState = .zero

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

            delegate?.onChange(isValid: feeModule.isValid && feePriorityModule.feeRateState.isValid && estimateGasLimitState.isValid)
        } catch {
            delegate?.onChange(isValid: false)
        }
    }

    private func processFee(error: Error) {
        feeModule.set(externalError: error is Erc20Kit.ValidationError ? nil : error)
    }

    private func syncState() {
        if feePriorityModule.feeRateState.isLoading || estimateGasLimitState.isLoading {
            amountModule.set(loading: true)

            feeModule.set(externalError: nil)
            feeModule.set(loading: true)
            return
        }
        amountModule.set(loading: false)
        feeModule.set(loading: false)

        if case let .error(error) = feePriorityModule.feeRateState {
            feeModule.set(fee: 0)
            // show primary error from feeRateKit
            processFee(error: error)
        } else if case let .error(error) = estimateGasLimitState {
            feeModule.set(fee: 0)
            // show secondary error from ethereum kit
            processFee(error: error)
        } else if case let .value(feeRateValue) = feePriorityModule.feeRateState, case let .value(estimateGasLimitValue) = estimateGasLimitState {
            amountModule.set(availableBalance: interactor.availableBalance(gasPrice: feeRateValue, gasLimit: estimateGasLimitValue))

            feeModule.set(externalError: nil)
            feeModule.set(fee: interactor.fee(gasPrice: feeRateValue, gasLimit: estimateGasLimitValue))
        }
    }

    private func syncEstimateGasLimit() {
        guard let address = try? addressModule.validAddress() else {
            onReceive(gasLimit: 0)
            return
        }
        gasDisposeBag = DisposeBag()

        estimateGasLimitState = .loading
        syncState()
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
        syncState()

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
        syncState()
        syncValidation()
        syncEstimateGasLimit()
    }

}

extension SendEthereumHandler {

    func onReceive(gasLimit: Int) {
        estimateGasLimitState = .value(gasLimit)

        syncState()
        syncValidation()
    }

    func onGasLimitError(_ error: Error) {
        estimateGasLimitState = .error(error)

        syncState()
        syncValidation()
    }

}

private enum SendEthereumError: LocalizedError {
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return "Server error: \(message)".localized
        }
    }

}

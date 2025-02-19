import UIKit
import RxSwift
import SnapKit

class SendViewController: WalletViewController {
    private let disposeBag = DisposeBag()

    private let delegate: ISendViewDelegate

    private let scrollView = UIScrollView()
    private let container = UIView()
    private let iconImageView = UIImageView()
    private let sendHolderView = UIView()
    private let sendButton: UIButton = .appYellow

    private let views: [UIView]

    init(delegate: ISendViewDelegate, views: [UIView]) {
        self.delegate = delegate
        self.views = views

        super.init()

        sendHolderView.addSubview(sendButton)
        sendHolderView.backgroundColor = .clear
        sendHolderView.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.sendButtonHolderHeight)
        }
        sendButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(SendTheme.margin)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(SendTheme.sendButtonHeight)
        }
        sendButton.addTarget(self, action: #selector(onSendTouchUp), for: .touchUpInside)
        sendButton.setTitle("send.next_button".localized, for: .normal)
    }

    @objc func onClose() {
        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        scrollView.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view)
            maker.top.bottom.equalTo(self.scrollView)
        }

        iconImageView.tintColor = .cryptoGray

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onClose))

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        sendButton.isEnabled = false

        buildViews()

        delegate.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        delegate.showKeyboard()
    }

    private func buildViews() {
        var lastView: UIView?
        for view in views {
            add(view: view, lastView: lastView)
            lastView = view
        }

        add(view: sendHolderView, lastView: lastView, last: true)
    }

    private func add(view: UIView, lastView: UIView?, last: Bool = false) {
        container.addSubview(view)
        if let lastView = lastView {
            view.snp.makeConstraints { maker in
                maker.leading.equalTo(self.view.snp.leading)
                maker.trailing.equalTo(self.view.snp.trailing)
                maker.top.equalTo(lastView.snp.bottom)
                if last {
                    maker.bottom.equalToSuperview()
                }
            }
        } else {
            view.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.leading.equalTo(self.view.snp.leading)
                maker.trailing.equalTo(self.view.snp.trailing)
                if last {
                    maker.bottom.equalToSuperview()
                }
            }
        }
    }

    @objc private func onSendTouchUp() {
        delegate.onProceedClicked()
    }

}

extension SendViewController: ISendView {

    func set(coin: Coin) {
        title = "send.title".localized(coin.code)
        iconImageView.image = UIImage(named: "\(coin.code.lowercased())")?.withRenderingMode(.alwaysTemplate)
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func show(error: Error) {
        let errorString: String
        if let localizedError = error as? LocalizedError {
            errorString = localizedError.localizedDescription
        } else {
            errorString = "\("alert.unknown_error".localized) \(String(reflecting: error))"
        }

        HudHelper.instance.showError(title: errorString)
    }

    func showProgress() {
        HudHelper.instance.showSpinner(userInteractionEnabled: false)
    }

    func set(sendButtonEnabled: Bool) {
        sendButton.isEnabled = sendButtonEnabled
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func dismissWithSuccess() {
        navigationController?.dismiss(animated: true)
        HudHelper.instance.showSuccess()
    }

}

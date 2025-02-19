import UIKit
import SnapKit

class SendConfirmationFieldCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let fieldTextLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(titleLabel)
        addSubview(fieldTextLabel)

        titleLabel.textColor = .cryptoGray
        titleLabel.font = .appSubhead2

        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.bottom.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        fieldTextLabel.textColor = .cryptoGray
        fieldTextLabel.font = .appSubhead2

        fieldTextLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.bottom.equalToSuperview()
        }

        fieldTextLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        fieldTextLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String, text: String) {
        titleLabel.text = title
        fieldTextLabel.text = text
    }

}

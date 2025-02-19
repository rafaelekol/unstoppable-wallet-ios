import UIKit

class RateListHeaderView: UITableViewHeaderFooterView {
    private let currentDateLabel = UILabel()
    private let lastUpdateLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        currentDateLabel.textColor = .appOz
        currentDateLabel.font = .appTitle1

        contentView.addSubview(currentDateLabel)
        currentDateLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        currentDateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin6x)
        }

        lastUpdateLabel.textColor = .appGray
        lastUpdateLabel.font = .appCaption
        lastUpdateLabel.numberOfLines = 2
        lastUpdateLabel.textAlignment = .right

        contentView.addSubview(lastUpdateLabel)
        lastUpdateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lastUpdateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        lastUpdateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(currentDateLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String, lastUpdated: String?) {
        currentDateLabel.text = title
        lastUpdateLabel.text = lastUpdated
    }

}

extension RateListHeaderView {

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        text.height(forContainerWidth: containerWidth, font: .appTitle1) + CGFloat.margin6x + CGFloat.margin4x
    }

}

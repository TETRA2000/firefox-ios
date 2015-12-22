/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Storage

struct LoginTableViewCellUX {
    static let highlightedLabelFont = UIFont.systemFontOfSize(12)
    static let highlightedLabelTextColor = UIConstants.HighlightBlue

    static let descriptionLabelFont = UIFont.systemFontOfSize(16)
    static let descriptionLabelTextColor = UIColor.blackColor()

    static let HorizontalMargin: CGFloat = 14
    static let IconImageSize: CGFloat = 34
}

enum LoginTableViewCellStyle {
    case IconAndBothLabels
    case NoIconAndBothLabels
    case IconAndDescriptionLabel
}

class LoginTableViewCell: UITableViewCell {

    private let labelContainer = UIView()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = LoginTableViewCellUX.descriptionLabelFont
        label.textColor = LoginTableViewCellUX.descriptionLabelTextColor
        label.textAlignment = .Left
        label.backgroundColor = UIColor.whiteColor()
        label.numberOfLines = 1
        return label
    }()

    let highlightedLabel: UILabel = {
        let label = UILabel()
        label.font = LoginTableViewCellUX.highlightedLabelFont
        label.textColor = LoginTableViewCellUX.highlightedLabelTextColor
        label.textAlignment = .Left
        label.backgroundColor = UIColor.whiteColor()
        label.numberOfLines = 1
        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.whiteColor()
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }()

    private lazy var customSelectionBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        return view
    }()

    var style: LoginTableViewCellStyle = .IconAndBothLabels {
        didSet {
            if style != oldValue {
                configureLayoutForStyle(style)
            }
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.whiteColor()
        labelContainer.backgroundColor = UIColor.whiteColor()

        labelContainer.addSubview(highlightedLabel)
        labelContainer.addSubview(descriptionLabel)

        contentView.addSubview(iconImageView)
        contentView.addSubview(labelContainer)

        configureLayoutForStyle(self.style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLayoutForStyle(style: LoginTableViewCellStyle) {
        switch style {
        case .IconAndBothLabels:
            iconImageView.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.left.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
                make.height.width.equalTo(LoginTableViewCellUX.IconImageSize)
            }

            labelContainer.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.right.equalTo(contentView).offset(-LoginTableViewCellUX.HorizontalMargin)
                make.left.equalTo(iconImageView.snp_right).offset(LoginTableViewCellUX.HorizontalMargin)
            }

            highlightedLabel.snp_remakeConstraints { make in
                make.left.top.equalTo(labelContainer)
                make.bottom.equalTo(descriptionLabel.snp_top)
                make.width.lessThanOrEqualTo(labelContainer)
            }

            descriptionLabel.snp_remakeConstraints { make in
                make.left.bottom.equalTo(labelContainer)
                make.top.equalTo(highlightedLabel.snp_bottom)
                make.width.lessThanOrEqualTo(labelContainer)
            }
        case .IconAndDescriptionLabel:
            iconImageView.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.left.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
                make.height.width.equalTo(LoginTableViewCellUX.IconImageSize)
            }

            labelContainer.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.right.equalTo(contentView).offset(-LoginTableViewCellUX.HorizontalMargin)
                make.left.equalTo(iconImageView.snp_right).offset(LoginTableViewCellUX.HorizontalMargin)
            }

            highlightedLabel.snp_remakeConstraints { make in
                make.height.width.equalTo(0)
            }

            descriptionLabel.snp_remakeConstraints { make in
                make.top.left.bottom.equalTo(labelContainer)
                make.width.lessThanOrEqualTo(labelContainer)
            }
        case .NoIconAndBothLabels:
            iconImageView.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.left.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
                make.height.width.equalTo(0)
            }

            labelContainer.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.right.equalTo(contentView).offset(-LoginTableViewCellUX.HorizontalMargin)
                make.left.equalTo(iconImageView.snp_right)
            }

            highlightedLabel.snp_remakeConstraints { make in
                make.left.top.equalTo(labelContainer)
                make.bottom.equalTo(descriptionLabel.snp_top)
                make.width.lessThanOrEqualTo(labelContainer)
            }

            descriptionLabel.snp_remakeConstraints { make in
                make.left.bottom.equalTo(labelContainer)
                make.top.equalTo(highlightedLabel.snp_bottom)
                make.width.lessThanOrEqualTo(labelContainer)
            }
        }

        setNeedsUpdateConstraints()
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        selectedBackgroundView = editing ? customSelectionBackground : nil
    }
}

// MARK: - Cell Decorators
extension LoginTableViewCell {
    func updateCellWithLogin(login: LoginData) {
        descriptionLabel.text = login.hostname
        highlightedLabel.text = login.username
        iconImageView.image = UIImage(named: "settingsFlatfox")
    }
}
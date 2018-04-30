//
//  PPTipJarTableViewCell.swift
//  Pushpin
//
//  Created by Daniel Loewenherz on 10/20/17.
//  Copyright © 2017 Lionheart Software. All rights reserved.
//

import UIKit
import QuickTableView
import SuperLayout
import LionheartExtensions

enum TipJarFrequency {
    case monthly
    case yearly
    case oneTime

    var description: String {
        switch self {
        case .monthly: return "monthly"
        case .yearly: return "yearly"
        case .oneTime: return "one-time"
        }
    }
}

extension UIImage {
    convenience init?(color: UIColor) {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.setFillColor(color.cgColor)
        context.fill(rect)

        guard let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            return nil
        }

        UIGraphicsEndImageContext()

        self.init(cgImage: image)
    }
}

final class PPTipJarButton: UIButton {
    let disabledColor = UIColor.gray

    static var blue: UIColor {
        return UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                layer.borderColor = PPTipJarButton.blue.cgColor
            } else {
                layer.borderColor = disabledColor.cgColor
            }
        }
    }

    init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        clipsToBounds = true

        contentEdgeInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)

        layer.cornerRadius = 6
        layer.borderColor = PPTipJarButton.blue.cgColor
        layer.borderWidth = 1

        setBackgroundImage(UIImage(color: .white), for: .normal)
        setBackgroundImage(UIImage(color: PPTipJarButton.blue), for: .highlighted)

        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
    }

    func setAmount(amount: String, frequency: TipJarFrequency) {
        let string = NSMutableAttributedString()
        string.append(NSAttributedString(string: amount + "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]))
        string.append(NSAttributedString(string: frequency.description, attributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ]))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center

        string.addAttribute(.paragraphStyle, value: paragraphStyle)
        string.addAttribute(.foregroundColor, value: PPTipJarButton.blue)
        setAttributedTitle(string, for: .normal)

        let highlightedString = NSMutableAttributedString(attributedString: string)
        highlightedString.addAttribute(.foregroundColor, value: UIColor.white)
        setAttributedTitle(highlightedString, for: .highlighted)

        let disabledString = NSMutableAttributedString(attributedString: string)
        disabledString.addAttribute(.foregroundColor, value: disabledColor)
        setAttributedTitle(disabledString, for: .disabled)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

final class PPTipJarTableViewCell: UITableViewCell {
    var theTextLabel: UILabel!
    var theDetailTextLabel: UILabel!
    var tipJarButton: PPTipJarButton!

    var rightConstraints: [NSLayoutConstraint] = []

    override var textLabel: UILabel? { return theTextLabel }
    override var detailTextLabel: UILabel? { return theDetailTextLabel }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        accessoryType = .none

        theTextLabel = UILabel()
        theTextLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        theTextLabel.translatesAutoresizingMaskIntoConstraints = false
        theTextLabel.textColor = .black
        theTextLabel.textAlignment = .left

        theDetailTextLabel = UILabel()
        theDetailTextLabel.numberOfLines = 0
        theDetailTextLabel.lineBreakMode = .byWordWrapping
        theDetailTextLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        theDetailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        theDetailTextLabel.textColor = .darkGray
        theDetailTextLabel.textAlignment = .left

        tipJarButton = PPTipJarButton()

        contentView.addSubview(theTextLabel)
        contentView.addSubview(theDetailTextLabel)
        contentView.addSubview(tipJarButton)

        let margins = contentView.layoutMarginsGuide

        theTextLabel.topAnchor ~~ margins.topAnchor
        theTextLabel.leadingAnchor ~~ margins.leadingAnchor

        theDetailTextLabel.topAnchor ~~ theTextLabel.bottomAnchor
        theDetailTextLabel.leadingAnchor ~~ margins.leadingAnchor
        theDetailTextLabel.bottomAnchor ~~ margins.bottomAnchor

        theTextLabel.rightAnchor ≤≤ tipJarButton.leftAnchor - 10
        theDetailTextLabel.rightAnchor ≤≤ tipJarButton.leftAnchor - 10

        tipJarButton.centerYAnchor ~~ margins.centerYAnchor
        tipJarButton.trailingAnchor ~~ margins.trailingAnchor
        tipJarButton.bottomAnchor ≤≤ margins.bottomAnchor

        tipJarButton.widthAnchor ~~ 70

        updateConstraintsIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepare(amount: String, frequency: TipJarFrequency) {
        tipJarButton.setAmount(amount: amount, frequency: frequency)
    }
}

extension PPTipJarTableViewCell: QuickTableViewCellIdentifiable {
    static var identifier: String { return "PPTipJarTableViewCellIdentifier" }
}

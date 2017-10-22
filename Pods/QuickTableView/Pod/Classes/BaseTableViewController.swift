//
//  Copyright 2016 Lionheart Software LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//

import KeyboardAdjuster
import UIKit

/**
 A base table view with built-in support for keyboard display and same initialization defaults.

 - author: Daniel Loewenherz
 - copyright: ©2016 Lionheart Software LLC
 - date: April 12, 2016
 */
@objc open class BaseTableViewController: UIViewController, KeyboardAdjuster, HasTableView {
    open var tableViewTopConstraint: NSLayoutConstraint!
    open var tableViewLeftConstraint: NSLayoutConstraint!
    open var tableViewRightConstraint: NSLayoutConstraint!

    open var keyboardAdjustmentHelper = KeyboardAdjustmentHelper()
    open var tableView: UITableView!

    @objc public init(style: UITableViewStyle = .grouped) {
        super.init(nibName: nil, bundle: nil)

        edgesForExtendedLayout = []
        definesPresentationContext = true

        tableView = UITableView(frame: CGRect.zero, style: style)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self as? UITableViewDelegate
        tableView.dataSource = self as? UITableViewDataSource

        if #available(iOS 11, *) {
            // Handle odd content inset adjustment animation on iOS 11
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            // iOS 11 and below need to have auto-layout specified manually
            tableView.estimatedRowHeight = 44
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activateKeyboardAdjuster()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deactivateKeyboardAdjuster()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        tableViewLeftConstraint = tableView.leftAnchor.constraint(equalTo: view.leftAnchor)
        tableViewRightConstraint = tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)

        tableViewLeftConstraint.isActive = true
        tableViewTopConstraint.isActive = true
        tableViewRightConstraint.isActive = true
        keyboardAdjustmentHelper.constraint = view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
    }

    // MARK: -
    open func leftBarButtonItemDidTouchUpInside(_ sender: AnyObject?) {
        parent?.dismiss(animated: true, completion: nil)
    }

    open func rightBarButtonItemDidTouchUpInside(_ sender: AnyObject?) {
        parent?.dismiss(animated: true, completion: nil)
    }

    open func rectForRow(at indexPath: IndexPath) -> CGRect {
        let rect = tableView.rectForRow(at: indexPath)
        return tableView.convert(rect, to: view)
    }
}

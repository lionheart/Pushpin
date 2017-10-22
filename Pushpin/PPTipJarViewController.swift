//
//  PPTipJarViewController.swift
//  Pushpin
//
//  Created by Daniel Loewenherz on 10/20/17.
//  Copyright © 2017 Lionheart Software. All rights reserved.
//

import UIKit
import QuickTableView
import StoreKit

protocol IAPRow {
    var frequency: TipJarFrequency { get }
    var productIdentifier: String { get }
}

extension IAPRow where Self: RawRepresentable, Self.RawValue == Int {
    static var productIdentifiers: [String] {
        var identifiers: [String] = []
        for i in 0..<Int.max {
            guard let identifier = Self(rawValue: i)?.productIdentifier else {
                break
            }

            identifiers.append(identifier)
        }

        return identifiers
    }
}

final class PPTipJarViewController: BaseTableViewController {
    var purchased = false
    var products: [String: SKProduct]?
    var sectionContainer: Section.Container {
        return Section.Container(productsLoaded: products != nil, purchased: purchased)
    }

    enum Section: Int, QuickTableViewSectionWithConditions {
        struct Container {
            var productsLoaded: Bool
            var purchased: Bool
        }

        case top
        case subscription
        case oneTime
        case loading
        case thankYou

        static func conditionalSections(for container: PPTipJarViewController.Section.Container) -> [(PPTipJarViewController.Section, Bool)] {
            return [
                (.top, !container.purchased),
                (.subscription, container.productsLoaded && !container.purchased),
                (.oneTime, container.productsLoaded && !container.purchased),
                (.loading, !container.productsLoaded),
                (.thankYou, container.purchased)
            ]
        }
    }

    enum SubscriptionRow: Int, QuickTableViewRow, IAPRow {
        case monthly
        case yearly

        static var title: String { return "Ongoing Tips ❤️" }

        var frequency: TipJarFrequency {
            switch self {
            case .monthly: return .monthly
            case .yearly: return .yearly
            }
        }

        var productIdentifier: String {
            switch self {
            case .monthly: return "com.lionheartsw.Pushpin.TipJarSubscription.Monthly"
            case .yearly: return "com.lionheartsw.Pushpin.TipJarSubscription.Yearly"
            }
        }
    }

    enum OneTimeRow: Int, QuickTableViewRow, IAPRow {
        case small
        case medium
        case large
        case huge
        case massive

        static var title: String { return "One-Time Tips" }

        var frequency: TipJarFrequency { return .oneTime }

        var productIdentifier: String {
            switch self {
            case .small: return "com.lionheartsw.Pushpin.Tip.Small"
            case .medium: return "com.lionheartsw.Pushpin.Tip.Medium"
            case .large: return "com.lionheartsw.Pushpin.Tip.Large"
            case .huge: return "com.lionheartsw.Pushpin.Tip.Huge"
            case .massive: return "com.lionheartsw.Pushpin.Tip.Massive"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Tip Jar"

        let identifiers = SubscriptionRow.productIdentifiers + OneTimeRow.productIdentifiers
        let request = SKProductsRequest(productIdentifiers: Set(identifiers))
        request.delegate = self
        request.start()

//        let receiptURL = Bundle.main.appStoreReceiptURL
//        let receipt = NSData(contentsOf: receiptURL!)
//        let requestContents: [String: Any] = [
//            "receipt-data": receipt!.base64EncodedString(options: []),
//            "password": "your iTunes Connect shared secret"
//        ]

        tableView.registerClass(MultilineTableViewCell.self)
        tableView.registerClass(ActivityIndicatorTableViewCell.self)
        tableView.registerClass(PPTipJarTableViewCell.self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        SKPaymentQueue.default().remove(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        SKPaymentQueue.default().add(self)
    }

    func addPaymentForIAP(row: IAPRow) {
        guard let products = self.products,
            let product = products[row.productIdentifier] else {
                return
        }

        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    @objc func monthlyTipButtonDidTouchUpInside() { addPaymentForIAP(row: SubscriptionRow.monthly) }
    @objc func yearlyTipButtonDidTouchUpInside() { addPaymentForIAP(row: SubscriptionRow.yearly) }
    @objc func smallTipButtonDidTouchUpInside() { addPaymentForIAP(row: OneTimeRow.small) }
    @objc func mediumTipButtonDidTouchUpInside() { addPaymentForIAP(row: OneTimeRow.medium) }
    @objc func largeTipButtonDidTouchUpInside() { addPaymentForIAP(row: OneTimeRow.large) }
    @objc func hugeTipButtonDidTouchUpInside() { addPaymentForIAP(row: OneTimeRow.huge) }
    @objc func massiveTipButtonDidTouchUpInside() { addPaymentForIAP(row: OneTimeRow.massive) }
}

// MARK: - UITableViewDelegate
extension PPTipJarViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension PPTipJarViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count(for: sectionContainer)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(section: section, container: sectionContainer) {
        case .top: return 1
        case .loading: return 1
        case .subscription: return SubscriptionRow.count
        case .oneTime: return OneTimeRow.count
        case .thankYou: return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(section: section, container: sectionContainer) {
        case .top: return nil
        case .loading: return nil
        case .subscription: return SubscriptionRow.title
        case .oneTime: return OneTimeRow.title
        case .thankYou: return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(section: section, container: sectionContainer) {
        case .top: return nil
        case .loading: return nil
        case .subscription: return nil
        case .oneTime: return """
Payment will be charged to your iTunes account at confirmation of purchase.

Your subscription will automatically renew unless auto-renew is turned off at least 24-hours before the end of the current subscription period.

Your account will be charged for renewal within 24-hours prior to the end of the current subscription period. Automatic renewals will cost the same price you were originally charged for the subscription.

You can manage your subscriptions and turn off auto-renewal by going to your Account Settings on the App Store after purchase.
"""
        case .thankYou: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row: IAPRow
        switch Section(at: indexPath, container: sectionContainer) {
        case .top:
            let cell = tableView.dequeueReusableCell(for: indexPath) as MultilineTableViewCell
            // Fun fact: Pushpin has never had a paid update since it was released in November 28, 2012. Pretty cool, right?
            cell.textLabel?.text = "Hi There"
            cell.detailTextLabel?.text = """
If you've been enjoying Pushpin for a while, and would like to show your support, please consider a tip. They go such a long way, and every little bit helps. Thanks! :)
"""
            return cell

        case .thankYou:
            let cell = tableView.dequeueReusableCell(for: indexPath) as MultilineTableViewCell
            // Fun fact: Pushpin has never had a paid update since it was released in November 28, 2012. Pretty cool, right?
            cell.textLabel?.text = "Thank You!"
            cell.detailTextLabel?.text = "Your generous tip goes such a long way. Thank you so much for your support!"
            return cell

        case .loading:
            return tableView.dequeueReusableCell(for: indexPath) as ActivityIndicatorTableViewCell

        case .subscription:
            row = SubscriptionRow(at: indexPath)

        case .oneTime:
            row = OneTimeRow(at: indexPath)
        }

        let cell = tableView.dequeueReusableCell(for: indexPath) as PPTipJarTableViewCell
        if let product = products?[row.productIdentifier] {
            let selector: Selector
            switch row {
            case SubscriptionRow.monthly: selector = #selector(monthlyTipButtonDidTouchUpInside)
            case SubscriptionRow.yearly: selector = #selector(yearlyTipButtonDidTouchUpInside)
            case OneTimeRow.small: selector = #selector(smallTipButtonDidTouchUpInside)
            case OneTimeRow.medium: selector = #selector(mediumTipButtonDidTouchUpInside)
            case OneTimeRow.large: selector = #selector(largeTipButtonDidTouchUpInside)
            case OneTimeRow.huge: selector = #selector(hugeTipButtonDidTouchUpInside)
            case OneTimeRow.massive: selector = #selector(massiveTipButtonDidTouchUpInside)
            default: return cell
            }
            cell.tipJarButton.addTarget(self, action: selector, for: .touchUpInside)
            cell.textLabel?.text = product.localizedTitle
            cell.detailTextLabel?.text = product.localizedDescription

            let currencyFormatter: NumberFormatter = {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = product.priceLocale
                formatter.maximumFractionDigits = 2
                return formatter
            }()

            if let formattedAmount = currencyFormatter.string(from: product.price) {
                cell.tipJarButton.setAmount(amount: formattedAmount, frequency: row.frequency)
            }
        }
        return cell
    }
}

extension PPTipJarViewController: SKProductsRequestDelegate {
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(error.localizedDescription)
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = [:]
        for product in response.products {
            products?[product.productIdentifier] = product
        }

        tableView.reloadData()
    }
}

// MARK: - SKPaymentTransactionObserver
extension PPTipJarViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                purchased = true

                queue.finishTransaction(transaction)

                tableView.reloadData()

            case .deferred:
                queue.finishTransaction(transaction)
                break

            case .failed:
                queue.finishTransaction(transaction)
                guard let error = transaction.error as? SKError else {
                    return
                }

                let message: String
                switch error {
                case SKError.unknown:
                    // This error occurs if running on the simulator.
                    message = error.localizedDescription

                case SKError.clientInvalid:
                    message = "This client is unauthorized to make in-app purchases."

                default:
                    message = error.localizedDescription
                }

                let alert = UIAlertController(title: "Purchase Error", message: message, preferredStyle: .alert)
                alert.addAction(title: "OK", style: .default, handler: nil)
                present(alert, animated: true)

            case .purchasing:
                break
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}

//
//  PPTipJarViewController.swift
//  Pushpin
//
//  Created by Dan Loewenherz on 5/6/18.
//  Copyright © 2018 Lionheart Software. All rights reserved.
//

import Foundation

#if !targetEnvironment(macCatalyst)

import TipJarViewController

struct ExampleTipJarOptions: TipJarConfiguration {
    static var topHeader = "Hi There"
    
    static var topDescription = """
If you've been enjoying Pushpin for a while, and would like to show your support, please consider a tip. They go such a long way, and every little bit helps. Thanks! :)
"""
    
    static func subscriptionProductIdentifier(for subscription: TipJarViewController<ExampleTipJarOptions>.SubscriptionRow) -> String {
        switch subscription {
        case .monthly: return "com.lionheartsw.Pushpin.TipJarSubscription.Monthly"
        case .yearly: return "com.lionheartsw.Pushpin.TipJarSubscription.Yearly"
        }
    }
    
    static func oneTimeProductIdentifier(for subscription: TipJarViewController<ExampleTipJarOptions>.OneTimeRow) -> String {
        switch subscription {
        case .small: return "com.lionheartsw.Pushpin.Tip.Small"
        case .medium: return "com.lionheartsw.Pushpin.Tip.Medium"
        case .large: return "com.lionheartsw.Pushpin.Tip.Large"
        case .huge: return "com.lionheartsw.Pushpin.Tip.Huge"
        case .massive: return "com.lionheartsw.Pushpin.Tip.Massive"
        }
    }
    
    static var termsOfUseURLString = "https://lionheartsw.com/software/pushpin/terms.html"
    static var privacyPolicyURLString = "https://lionheartsw.com/software/pushpin/privacy.html"
}

extension ExampleTipJarOptions: TipJarOptionalConfiguration {
    static var title = "Tip Jar"
    static var oneTimeTipsTitle = "One-Time Tips"
    static var subscriptionTipsTitle = "Ongoing Tips ❤️"
    static var receiptVerifierURLString = "https://iap-receipt-verifier.herokuapp.com/verify"
}

final class PPTipJarViewController: TipJarViewController<ExampleTipJarOptions> {
    
}

@objc class PPTipJarViewControllerFactory: NSObject {
    @objc public static var controller: UIViewController {
        return PPTipJarViewController()
    }
}

#endif

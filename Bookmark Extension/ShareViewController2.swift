//
//  ShareViewController2.swift
//  Bookmark Extension
//
//  Created by Daniel Loewenherz on 11/30/17.
//  Copyright © 2017 Lionheart Software. All rights reserved.
//

import UIKit

final class ShareViewController2: PPNavigationController {
    func displayNoURLAlert() {
        let message = "No URL was provided for this webpage. Please try using another browser. If you still experience issues, please contact support."
        let alert = UIAlertController(title: "No URL Found", message: message, preferredStyle: .alert)

//        UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:@"No URL Found" message:@"No URL was provided for this webpage. Please try using another browser. If you still experience issues, please contact support."];
//        [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
//            }];
//        [self presentViewController:alert animated:YES completion:nil];
    }
}

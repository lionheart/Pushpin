//
//  ShareViewController.swift
//  BookmarkExtension2
//
//  Created by Daniel Loewenherz on 7/10/16.
//  Copyright © 2016 Lionheart Software. All rights reserved.
//

import UIKit
import Social
import ASPinboard
import MobileCoreServices
import FMDB

final class ShareViewController: SLComposeServiceViewController {
    var hasToken = false
    var text: String?
    var url: String?

    override func isContentValid() -> Bool {
        return true
    }

    override func configurationItems() -> [AnyObject]! {
        return []
    }

    func didSelectPost(animated: Bool) {
        super.viewWillAppear(animated)

        let InvalidCredentials: UIViewController -> Void = { controller in
            dispatch_async(dispatch_get_main_queue()) { 
                let alert = UIAlertController(title: NSLocalizedString("Invalid Token", comment: ""), message: NSLocalizedString("Please open Pushpin to refresh your credentials.", comment: ""), preferredStyle: .Alert)
                alert.lhs_addActionWithTitle("OK", style: .Default) { action in
                    controller.dismissViewControllerAnimated(true, completion: { 
                        self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                    })
                }

                controller.presentViewController(alert, animated: true, completion: nil)
            }
        }

        // MARK: TODO
        let APP_GROUP = "io.aurora.pushpin"

        guard let defaults = NSUserDefaults.init(suiteName: APP_GROUP) else {
            return
        }

        let token = defaults.stringForKey("token")

        hasToken = token?.characters.count > 0
        text = nil

        if let token = token where hasToken {
            ASPinboard.sharedInstance().token = token
        }

        let PresentController: UINavigationController -> Void = { controller in
            guard let addBookmarkViewController = controller.topViewController as? PPAddBookmarkViewController else {
                return
            }

            addBookmarkViewController.presentingViewControllersExtensionContext = self.extensionContext
            addBookmarkViewController.tokenOverride = token

            controller.modalPresentationStyle = .FormSheet
            controller.modalTransitionStyle = .CoverVertical
            PPTheme.customizeUIElements()

            self.presentViewController(controller, animated: true, completion: {
                if self.hasToken {
                    ASPinboard.sharedInstance().lastUpdateWithSuccess({ _ in }, failure: { error in
                        InvalidCredentials(controller)
                    })
                }
                else {
                    InvalidCredentials(controller)
                }
            })
        }

        let CompletionHandler: (String?, String?, String?) -> Void = { urlString, title, description in
            dispatch_async(dispatch_get_main_queue()) {
                guard let urlString = urlString else {
                    return
                }

                var post: [NSObject: AnyObject] = [
                    "url": urlString
                ]

                if let title = title, let description = description {
                    post["title"] = title
                    post["description"] = description
                }

                var count: Int32 = 0

                guard let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(APP_GROUP),
                    let databasePath = containerURL.URLByAppendingPathComponent("shared.db").path else {
                    return
                }

                FMDatabaseQueue(path: databasePath).inDatabase { db in
                    let results = db.executeQuery("SELECT COUNT(*) AS count, * FROM bookmark WHERE url=?", withArgumentsInArray: [urlString])
                    results.next()
                    count = results.intForColumnIndex(0)

                    if count > 0 {
                        post = PPPinboardDataSource.postFromResultSet(results)
                    }
                }

                var navigation: PPNavigationController!
                if count > 0 {
                    navigation = PPAddBookmarkViewController.addBookmarkViewControllerWithBookmark(post, update: true, callback: nil)
                }
                else {
                    let privateByDefault = defaults.boolForKey("PrivateByDefault")
                    let readByDefault = defaults.boolForKey("ReadByDefault")

                    post["private"] = NSNumber(bool: privateByDefault)
                    post["unread"] = NSNumber(bool: !readByDefault)
                    navigation = PPAddBookmarkViewController.addBookmarkViewControllerWithBookmark(post, update: false, callback: nil)

                    if title == nil && description == nil {
                        let addBookmarkController = navigation.topViewController as? PPAddBookmarkViewController
                        addBookmarkController?.prefillTitleAndForceUpdate(true)
                    }
                }

                PresentController(navigation)
            }
        }

        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
        let attachments = item.attachments as? [NSItemProvider] else {
            return
        }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                provider.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil, completionHandler: { (url, error) in
                    self.url = (url as? NSURL)?.absoluteString
                    CompletionHandler(self.url, self.text, "")
                })
            }

            if provider.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                provider.loadItemForTypeIdentifier(kUTTypePlainText as String, options: nil, completionHandler: { (text, error) in
                    self.text = text as? String
                    CompletionHandler(self.url, self.text, "")
                })
            }

            if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                provider.loadItemForTypeIdentifier(kUTTypePropertyList as String, options: nil, completionHandler: { (results, error) in
                    guard let results = results as? [String: AnyObject],
                        let data = results[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: AnyObject] else {
                        return
                    }

                    let url = data["url"] as? String
                    let title = data["title"] as? String
                    let description = data["selection"] as? String
                    CompletionHandler(url, title, description)
                })
            }
        }
    }
}

//
//  AppDelegate.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 Lionheart Software LLC. All rights reserved.
//

@import UIKit;
@import MessageUI.MFMailComposeViewController;
@import StoreKit;

#import "PPPinboardLoginViewController.h"
#import "PPConstants.h"
#import "PPURLCache.h"
#import "PPSplitViewController.h"

@class PPFeedListViewController;
@class PPNavigationController;

@interface PPAppDelegate : UIResponder <UIApplicationDelegate,  UISplitViewControllerDelegate, MFMailComposeViewControllerDelegate, SKPaymentTransactionObserver> {
    BOOL didLaunchWithURL;
    BOOL timerPaused;
    NSInteger secondsLeft;
}

@property (nonatomic, strong) PPURLCache *urlCache;

@property (nonatomic) BOOL bookmarksLoading;

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic) BOOL bookmarksUpdated;

@property (nonatomic) BOOL connectionAvailable;
@property (nonatomic) BOOL hideURLPrompt;

@property (nonatomic, strong) NSString *bookmarksUpdatedMessage;
@property (nonatomic, strong) NSString *clipboardBookmarkTitle;
@property (nonatomic, strong) NSString *clipboardBookmarkURL;

@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) PPNavigationController *loginViewController;
@property (nonatomic, strong) PPNavigationController *navigationController;
@property (nonatomic, strong) PPSplitViewController *splitViewController;
@property (nonatomic, strong) PPFeedListViewController *feedListViewController;

- (NSMutableDictionary *)parseQueryParameters:(NSString *)query;

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)(NSDictionary *))callback;

- (void)promptUserToAddBookmark;
- (void)logout;

+ (PPAppDelegate *)sharedDelegate;

@end

//
//  AppDelegate.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@import UIKit;
@import MessageUI.MFMailComposeViewController;

#import "PPLoginViewController.h"
#import "PPConstants.h"
#import "PPURLCache.h"

#import <TextExpander/SMTEDelegateController.h>

@class PPNavigationController;
@class PPSplitViewController;
@class PPFeedListViewController;

@interface PPAppDelegate : UIResponder <UIApplicationDelegate,  UISplitViewControllerDelegate, MFMailComposeViewControllerDelegate> {
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

@property (nonatomic, strong) SMTEDelegateController *textExpander;

- (NSMutableDictionary *)parseQueryParameters:(NSString *)query;

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback;

- (void)promptUserToAddBookmark;
- (void)logout;

- (NSString *)defaultFeedDescription;

+ (PPAppDelegate *)sharedDelegate;

@end

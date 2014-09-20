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

#import <TextExpander/SMTEDelegateController.h>
#import <FMDB/FMDatabaseQueue.h>

@class PPNavigationController;
@class PPSplitViewController;
@class PPFeedListViewController;

@interface PPAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, UISplitViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    BOOL didLaunchWithURL;
    BOOL timerPaused;
    NSInteger secondsLeft;
}

@property (nonatomic) BOOL bookmarksLoading;

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic) BOOL bookmarksUpdated;

@property (nonatomic) BOOL connectionAvailable;

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

- (void)migrateDatabase;
- (void)deleteDatabaseFile;
- (void)resetDatabase;

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback;
- (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback;

- (void)openSettings;
- (void)promptUserToAddBookmark;
- (void)logout;

- (NSString *)defaultFeedDescription;

+ (PPAppDelegate *)sharedDelegate;
+ (NSString *)databasePath;
+ (FMDatabaseQueue *)databaseQueue;

@end

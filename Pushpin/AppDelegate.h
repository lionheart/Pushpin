//
//  AppDelegate.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "PPConstants.h"

#import <TextExpander/SMTEDelegateController.h>

@class FMDatabaseQueue;
@class PPNavigationController;
@class PPSplitViewController;
@class FeedListViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, UISplitViewControllerDelegate> {
    BOOL didLaunchWithURL;
    BOOL timerPaused;
    NSInteger secondsLeft;
}

@property (nonatomic) BOOL bookmarksLoading;
@property (nonatomic) BOOL bookmarksNeedUpdate;
@property (nonatomic) BOOL compressPosts;
@property (nonatomic) BOOL dimReadPosts;
@property (nonatomic) BOOL doubleTapToEdit;
@property (nonatomic) BOOL enableAutoCapitalize;
@property (nonatomic) BOOL enableAutoCorrect;
@property (nonatomic) BOOL markReadPosts;
@property (nonatomic) BOOL openLinksWithMobilizer;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic) BOOL bookmarksUpdated;

@property (nonatomic) PPBrowserType browser;
@property (nonatomic) PPMobilizerType mobilizer;
@property (nonatomic) PPReadLaterType readLater;

@property (nonatomic) BOOL connectionAvailable;
@property (nonatomic) BOOL openLinksInApp;
@property (nonatomic) BOOL privateByDefault;
@property (nonatomic) BOOL readByDefault;
@property (nonatomic) BOOL onlyPromptToAddOnce;
@property (nonatomic) BOOL alwaysShowClipboardNotification;
@property (nonatomic, strong) NSString *bookmarksUpdatedMessage;
@property (nonatomic, strong) NSString *clipboardBookmarkTitle;
@property (nonatomic, strong) NSString *clipboardBookmarkURL;
@property (nonatomic, strong) NSString *defaultFeed;
@property (nonatomic, strong) NSString *feedToken;
@property (nonatomic, strong) NSString *token;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) PPNavigationController *loginViewController;
@property (nonatomic, strong) PPNavigationController *navigationController;
@property (nonatomic, strong) PPSplitViewController *splitViewController;
@property (nonatomic, strong) FeedListViewController *feedListViewController;

@property (nonatomic, strong) SMTEDelegateController *textExpander;

- (NSMutableDictionary *)parseQueryParameters:(NSString *)query;
- (NSString *)username;
+ (AppDelegate *)sharedDelegate;
- (void)migrateDatabase;
+ (NSString *)databasePath;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback;
- (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback;

- (void)openSettings;
- (void)customizeUIElements;
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;
- (void)promptUserToAddBookmark;

- (NSString *)defaultFeedDescription;

@end

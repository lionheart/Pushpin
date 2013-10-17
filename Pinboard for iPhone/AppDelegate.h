//
//  AppDelegate.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HockeySDK/HockeySDK.h>
#import "LoginViewController.h"

enum browsers {
    BROWSER_WEBVIEW,
    BROWSER_SAFARI,
    BROWSER_CHROME,
    BROWSER_ICAB_MOBILE,
    BROWSER_DOLPHIN,
    BROWSER_CYBERSPACE,
    BROWSER_OPERA
};

enum readlaterservices {
    READLATER_NONE,
    READLATER_INSTAPAPER,
    READLATER_READABILITY,
    READLATER_POCKET,
    READLATER_NATIVE
};

enum mobilizers {
    MOBILIZER_GOOGLE,
    MOBILIZER_INSTAPAPER,
    MOBILIZER_READABILITY
};

enum bookmarkupdateevents {
    BOOKMARK_EVENT_ADD,
    BOOKMARK_EVENT_UPDATE,
    BOOKMARK_EVENT_DELETE
};

@class PrimaryNavigationViewController;
@class FMDatabaseQueue;

@protocol BookmarkUpdateProgressDelegate <NSObject>
- (void)bookmarkUpdateEvent:(NSNumber *)updated total:(NSNumber *)total;
@end

@protocol ModalDelegate <NSObject>
- (void)closeModal:(UIViewController *)sender;
- (void)closeModal:(UIViewController *)sender success:(void (^)())success;
@end

@protocol BookmarkUpdatedDelegate <NSObject>
- (void)bookmarkUpdateEvent:(int)type;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, ModalDelegate, BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate> {
    BOOL didLaunchWithURL;
    BOOL timerPaused;
    NSInteger secondsLeft;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSNumber *browser;
@property (nonatomic, retain) NSNumber *readlater;
@property (nonatomic, strong) NSNumber *mobilizer;
@property (nonatomic) BOOL compressPosts;
@property (nonatomic) BOOL dimReadPosts;
@property (nonatomic) BOOL markReadPosts;
@property (nonatomic) BOOL enableAutoCorrect;
@property (nonatomic) BOOL enableAutoCapitalize;
@property (nonatomic, strong) NSNumber *openLinksInApp;
@property (nonatomic, retain) NSNumber *privateByDefault;
@property (nonatomic, retain) NSNumber *readByDefault;
@property (nonatomic, retain) NSString *defaultFeed;
@property (nonatomic) BOOL doubleTapToEdit;
@property (nonatomic) BOOL openLinksWithMobilizer;
@property (nonatomic, retain) NSString *feedToken;
@property (nonatomic, weak) id<BookmarkUpdateProgressDelegate> bookmarkUpdateDelegate;
@property (nonatomic, retain) NSNumber *connectionAvailable;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UINavigationController *loginViewController;
@property (nonatomic) BOOL addBookmarkAlertViewIsVisible;

@property (nonatomic, strong) NSString *clipboardBookmarkTitle;
@property (nonatomic, strong) NSString *clipboardBookmarkURL;

@property (nonatomic, retain) NSNumber *bookmarksUpdated;
@property (nonatomic, retain) NSString *bookmarksUpdatedMessage;
@property (nonatomic, retain) NSTimer *refreshTimer;
@property (nonatomic) BOOL bookmarksLoading;
@property (nonatomic) BOOL bookmarksNeedUpdate;


- (NSMutableDictionary *)parseQueryParameters:(NSString *)query;
- (NSString *)username;
+ (AppDelegate *)sharedDelegate;
- (void)migrateDatabase;
+ (NSString *)databasePath;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate delegate:(id <ModalDelegate>)delegate callback:(void (^)())callback;
- (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback;

- (void)openSettings;
- (void)customizeUIElements;
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;
- (void)promptUserToAddBookmark;

- (NSString *)defaultFeedDescription;

+ (NSString *)heavyFontName;
+ (NSString *)mediumFontName;
+ (NSString *)bookFontName;
+ (NSString *)blackFontName;

@end

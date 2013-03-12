//
//  AppDelegate.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

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
    READLATER_POCKET
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
@end

@protocol BookmarkUpdatedDelegate <NSObject>
- (void)bookmarkUpdateEvent:(int)type;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate> {
    BOOL didLaunchWithURL;
    BOOL timerPaused;
    NSInteger secondsLeft;
}

@property (nonatomic, retain) PrimaryNavigationViewController *navigationViewController;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSNumber *browser;
@property (nonatomic, retain) NSNumber *readlater;
@property (nonatomic, retain) NSNumber *privateByDefault;
@property (nonatomic, retain) NSNumber *readByDefault;
@property (nonatomic, retain) NSString *feedToken;
@property (nonatomic, retain) id<BookmarkUpdateProgressDelegate> bookmarkUpdateDelegate;
@property (nonatomic, retain) NSNumber *connectionAvailable;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;

@property (nonatomic, retain) NSNumber *bookmarksUpdated;
@property (nonatomic, retain) NSString *bookmarksUpdatedMessage;
@property (nonatomic, retain) FMDatabaseQueue *dbQueue;
@property (nonatomic, retain) NSTimer *refreshTimer;
@property (nonatomic) BOOL bookmarksLoading;

- (NSMutableDictionary *)parseQueryParameters:(NSString *)query;
- (NSString *)username;
+ (AppDelegate *)sharedDelegate;
- (void)migrateDatabase;
- (void)updateBookmarks;
- (void)forceUpdateBookmarks:(id<BookmarkUpdateProgressDelegate>)updateDelegate;
- (void)updateBookmarksWithDelegate:(id<BookmarkUpdateProgressDelegate>)updateDelegate;
- (void)updateNotes;
+ (NSString *)databasePath;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback;
- (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback;

- (void)pauseRefreshTimer;
- (void)resumeRefreshTimer;
- (void)executeTimer;
- (void)openSettings;
- (void)customizeUIElements;
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;

@end

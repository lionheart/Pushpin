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
    BROWSER_CHROME
};

enum readlaterservices {
    READLATER_NONE,
    READLATER_INSTAPAPER,
    READLATER_READABILITY
};

enum bookmarkupdateevents {
    BOOKMARK_EVENT_ADD,
    BOOKMARK_EVENT_UPDATE,
    BOOKMARK_EVENT_DELETE
};

@class TabBarViewController;

@protocol BookmarkUpdateProgressDelegate <NSObject>
- (void)bookmarkUpdateEvent:(NSNumber *)updated total:(NSNumber *)total;
@end

@protocol ModalDelegate <NSObject>
- (void)closeModal;
@end

@protocol BookmarkUpdatedDelegate <NSObject>
- (void)bookmarkUpdateEvent:(int)type;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) TabBarViewController *tabBarViewController;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSNumber *browser;
@property (nonatomic, retain) NSNumber *readlater;
@property (nonatomic, retain) NSNumber *privateByDefault;
@property (nonatomic, retain) NSString *feedToken;
@property (nonatomic, retain) id<BookmarkUpdateProgressDelegate> bookmarkUpdateDelegate;
@property (nonatomic, retain) NSNumber *connectionAvailable;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;

- (NSString *)username;
+ (AppDelegate *)sharedDelegate;
- (void)migrateDatabase;
- (void)updateBookmarks;
- (void)forceUpdateBookmarks:(id<BookmarkUpdateProgressDelegate>)updateDelegate;
- (void)updateBookmarksWithDelegate:(id<BookmarkUpdateProgressDelegate>)updateDelegate;
- (void)updateNotes;
+ (NSString *)databasePath;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)aURL andTitle:(NSString *)aTitle;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)aURL andTitle:(NSString *)aTitle andTags:(NSString *)someTags;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)aURL andTitle:(NSString *)aTitle andTags:(NSString *)someTags andDescription:(NSString *)aDescription;
- (void)showAddBookmarkViewControllerWithURL:(NSString *)aURL andTitle:(NSString *)aTitle andTags:(NSString *)someTags andDescription:(NSString *)aDescription andPrivate:(NSNumber *)isPrivate andRead:(NSNumber *)isRead;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark andDelegate:(id<BookmarkUpdatedDelegate>)delegate;
- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark andDelegate:(id<BookmarkUpdatedDelegate>)delegate update:(NSNumber *)isUpdate;

@end

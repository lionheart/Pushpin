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

@class TabBarViewController;

@protocol BookmarkUpdateProgressDelegate <NSObject>
- (void)bookmarkUpdateEvent:(NSNumber *)updated total:(NSNumber *)total;
@end

@protocol ModalDelegate <NSObject>
- (void)closeModal;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) TabBarViewController *tabBarViewController;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSNumber *browser;
@property (nonatomic, retain) id<BookmarkUpdateProgressDelegate> bookmarkUpdateDelegate;
@property (nonatomic, retain) NSNumber *connectionAvailable;

+ (AppDelegate *)sharedDelegate;
- (void)migrateDatabase;
- (void)updateBookmarks;
- (void)updateBookmarksWithDelegate:(id<BookmarkUpdateProgressDelegate>)updateDelegate;
- (void)updateNotes;
+ (NSString *)databasePath;

@end

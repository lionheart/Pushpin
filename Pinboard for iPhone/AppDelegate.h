//
//  AppDelegate.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pinboard.h"
#import <CoreData/CoreData.h>

@protocol BookmarkUpdateProgressDelegate <NSObject>

- (void)bookmarkUpdateEvent:(NSNumber *)updated total:(NSNumber *)total;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) id<BookmarkUpdateProgressDelegate> bookmarkUpdateDelegate;

+ (AppDelegate *)sharedDelegate;
- (void)updateBookmarks;
- (void)deleteBookmarks;
- (void)updateBookmarksWithDelegate:(id<BookmarkUpdateProgressDelegate>)updateDelegate;
- (void)updateNotes;
+ (NSString *)databasePath;

@end

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Pushpin for Pinboard
 * Copyright (C) 2025 Lionheart Software LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

//
//  PPDataSource.h
//  Pushpin
//
//  Created by Dan Loewenherz on 3/25/14.
//
//

@import UIKit;

#import "PostMetadata.h"
#import "PPNavigationController.h"
#import "PPTitleButton.h"

static dispatch_queue_t PPBookmarkUpdateQueue() {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.aurora.Pushpin.BookmarkUpdateQueue", 0);
    });
    return queue;
}

static dispatch_queue_t PPBookmarkReloadQueue() {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.aurora.Pushpin.BookmarkReloadQueue", 0);
    });
    return queue;
}

@protocol PPDataSource <NSObject>

- (PostMetadata *)metadataForPostAtIndex:(NSInteger)index;
- (PostMetadata *)compressedMetadataForPostAtIndex:(NSInteger)index;

- (NSInteger)indexForPost:(NSDictionary *)post;
- (NSInteger)numberOfPosts;
- (BOOL)searchSupported;

- (NSAttributedString *)titleForPostAtIndex:(NSInteger)index;
- (NSAttributedString *)descriptionForPostAtIndex:(NSInteger)index;
- (NSAttributedString *)linkForPostAtIndex:(NSInteger)index;

- (CGFloat)heightForPostAtIndex:(NSInteger)index;
- (CGFloat)compressedHeightForPostAtIndex:(NSInteger)index;

- (BOOL)isPostAtIndexPrivate:(NSInteger)index;
- (BOOL)supportsTagDrilldown;

- (NSDictionary *)postAtIndex:(NSInteger)index;
- (NSString *)urlForPostAtIndex:(NSInteger)index;

// Retrieves bookmarks from remote server and inserts them into database.
- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *error))completion
                           progress:(void (^)(NSInteger, NSInteger))progress
                            options:(NSDictionary *)options;

- (void)syncBookmarksWithCompletion:(void (^)(BOOL updated, NSError *error))completion
                           progress:(void (^)(NSInteger, NSInteger))progress;

// Refreshes local cache.
- (void)reloadBookmarksWithCompletion:(void (^)(NSError *error))completion
                               cancel:(BOOL (^)(void))cancel
                                width:(CGFloat)width;

- (PPPostActionType)actionsForPost:(NSDictionary *)post;

@optional

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic) NSInteger totalNumberOfPosts;

- (BOOL)isPostAtIndexStarred:(NSInteger)index;

- (NSString *)searchPlaceholder;

- (NSArray *)badgesForPostAtIndex:(NSInteger)index;

- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index callback:(void (^)(void))callback;
- (PPNavigationController *)editViewControllerForPostAtIndex:(NSInteger)index;
- (id <PPDataSource>)searchDataSource;
- (void)filterWithQuery:(NSString *)query;
- (void)addDataSource:(void (^)(void))callback;
- (void)removeDataSource:(void (^)(void))callback;

// A data source may alternatively provide a UIViewController to push
- (NSInteger)sourceForPostAtIndex:(NSInteger)index;
- (UIViewController *)viewControllerForPostAtIndex:(NSInteger)index;
- (void)handleTapOnLinkWithURL:(NSURL *)url callback:(void (^)(UIViewController *))callback;

- (PPNavigationController *)addViewControllerForPostAtIndex:(NSInteger)index;
- (void)markPostAsRead:(NSString *)url callback:(void (^)(NSError *))callback;
- (void)deletePosts:(NSArray *)posts callback:(void (^)(NSIndexPath *))callback;
- (void)deletePostsAtIndexPaths:(NSArray *)indexPaths callback:(void (^)(void))callback;

/**
 * Called when post at a specific index path is called
 */
- (void)willDisplayIndexPath:(NSIndexPath *)indexPath callback:(void (^)(BOOL))callback;

/**
 * The navigation bar color.
 */
- (UIColor *)barTintColor;

/**
 * The title to display.
 */
- (NSString *)title;

/**
 * The title view to display (overrides title).
 */
- (UIView *)titleView;

/**
 * Set up the title view with a specific object as the delegate
 */
- (UIView *)titleViewWithDelegate:(id<PPTitleButtonDelegate>)delegate;

@end

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
//  PinboardDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

@import Foundation;
@import ASPinboard;

#import "PPDataSource.h"
#import "PPConstants.h"

static NSString *kPinboardDataSourceProgressNotification __unused = @"kPinboardDataSourceProgressNotification";
static NSString *PinboardDataSourceErrorDomain __unused = @"PinboardDataSourceErrorDomain";

enum PINBOARD_DATA_SOURCE_ERROR_CODES {
    PinboardErrorSyncInProgress
};

@class FMResultSet;
@class PostMetadata;

@interface PPPinboardDataSource : NSObject <PPDataSource, NSCopying>

@property (nonatomic) NSInteger totalNumberOfPosts;
@property (nonatomic, strong) NSMutableDictionary *tagsWithFrequency;
@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *enUSPOSIXDateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *metadata;
@property (nonatomic, strong) NSMutableArray *compressedMetadata;
@property (nonatomic) ASPinboardSearchScopeType searchScope;

#pragma mark Query

@property (nonatomic) kPushpinFilterType untagged;
@property (nonatomic) kPushpinFilterType starred;
@property (nonatomic) kPushpinFilterType unread;

// private is a protected word in Objective-C
@property (nonatomic) kPushpinFilterType isPrivate;

@property (nonatomic, strong) NSArray *tags;
@property (nonatomic) NSInteger offset;
@property (nonatomic) NSInteger limit;
@property (nonatomic) NSString *orderBy;
@property (nonatomic, strong) NSString *searchQuery;

- (void)updateStarredPostsWithCompletion:(PPErrorBlock)completion;

- (void)filterWithQuery:(NSString *)query;
- (void)filterWithParameters:(NSDictionary *)parameters;
- (void)filterByPrivate:(kPushpinFilterType)isPrivate
               isUnread:(kPushpinFilterType)isUnread
              isStarred:(kPushpinFilterType)starred
               untagged:(kPushpinFilterType)untagged
                   tags:(NSArray *)tags
                 offset:(NSInteger)offset
                  limit:(NSInteger)limit;

- (PPPinboardDataSource *)searchDataSource;
- (PPPinboardDataSource *)dataSourceWithAdditionalTag:(NSString *)tag;
- (NSArray *)quotedTags;
+ (NSDictionary *)postFromResultSet:(FMResultSet *)resultSet;
+ (NSCache *)resultCache;

- (void)updateSpotlightSearchIndex;
- (void)BookmarksUpdatedTimeSuccessBlock:(NSDate *)updateTime count:(NSInteger)count completion:(void (^)(BOOL updated, NSError *))completion progress:(void (^)(NSInteger, NSInteger))progress skipStarred:(BOOL)skipStarred;
- (void)BookmarksSuccessBlock:(NSArray *)posts constraints:(NSDictionary *)constraints count:(NSInteger)count completion:(void (^)(BOOL updated, NSError *))completion progress:(void (^)(NSInteger, NSInteger))progress skipStarred:(BOOL)skipStarred;

@end

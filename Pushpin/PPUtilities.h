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
//  PPUtilities.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/14/14.
//
//

@import Foundation;
@import FMDB;

#import "PPConstants.h"

@interface PPUtilities : NSObject

+ (NSString *)stringByTrimmingWhitespace:(id)object;

+ (void)generateDiffForPrevious:(NSArray *)previousItems
                        updated:(NSArray *)updatedItems
                           hash:(NSString *(^)(id))extractHash
                           meta:(NSString *(^)(id))extractMeta
                     completion:(void (^)(NSSet *inserted, NSSet *updated, NSSet *deleted))completion;

+ (void)generateDiffForPrevious:(NSArray *)previousItems
                        updated:(NSArray *)updatedItems
                           hash:(NSString *(^)(id))extractHash
                     completion:(void (^)(NSSet *inserted, NSSet *deleted))completion;

+ (NSDictionary *)dictionaryFromResultSet:(FMResultSet *)resultSet;

+ (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback;

+ (kPushpinFilterType)inverseValueForFilter:(kPushpinFilterType)filter;

+ (UIAlertController *)saveSearchAlertControllerWithQuery:(NSString *)query
                                                isPrivate:(kPushpinFilterType)isPrivate
                                                   unread:(kPushpinFilterType)unread
                                                  starred:(kPushpinFilterType)starred
                                                   tagged:(kPushpinFilterType)tagged
                                               completion:(void (^)(void))completion;

+ (NSMutableSet *)staticAssetURLsForHTML:(NSString *)html;
+ (NSMutableSet *)staticAssetURLsForCachedURLResponse:(NSCachedURLResponse *)cachedURLResponse;

+ (void)migrateDatabase;
+ (void)resetDatabase;
+ (NSString *)databasePath;
+ (FMDatabaseQueue *)databaseQueue;

@end

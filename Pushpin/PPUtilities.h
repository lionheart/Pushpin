//
//  PPUtilities.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/14/14.
//
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabase.h>

#import "PPConstants.h"

@class FMResultSet;

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

+ (void)shareToReadLaterWithURL:(NSString *)url title:(NSString *)title;
+ (void)shareToReadLaterWithURL:(NSString *)url title:(NSString *)title delay:(CGFloat)seconds;
+ (void)shareToReadLaterWithURL:(NSString *)url title:(NSString *)title delay:(CGFloat)seconds completion:(void (^)())completion;
+ (void)shareToReadLater:(PPReadLaterType)readLater URL:(NSString *)url title:(NSString *)title delay:(CGFloat)seconds completion:(void (^)())completion;
+ (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback;

+ (kPushpinFilterType)inverseValueForFilter:(kPushpinFilterType)filter;

+ (UIAlertController *)saveSearchAlertControllerWithQuery:(NSString *)query
                                                isPrivate:(kPushpinFilterType)isPrivate
                                                   unread:(kPushpinFilterType)unread
                                                  starred:(kPushpinFilterType)starred
                                                   tagged:(kPushpinFilterType)tagged
                                               completion:(void (^)())completion;

+ (NSMutableSet *)staticAssetURLsForHTML:(NSString *)html;
+ (NSMutableSet *)staticAssetURLsForCachedURLResponse:(NSCachedURLResponse *)cachedURLResponse;

+ (void)migrateDatabase;
+ (void)resetDatabase;
+ (NSString *)databasePath;
+ (FMDatabaseQueue *)databaseQueue;

@end

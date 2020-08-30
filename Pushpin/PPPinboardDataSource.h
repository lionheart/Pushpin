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

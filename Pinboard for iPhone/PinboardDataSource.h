//
//  PinboardDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"
#import "PPConstants.h"

static NSString *kPinboardDataSourceProgressNotification __unused = @"kPinboardDataSourceProgressNotification";
static NSString *PinboardDataSourceErrorDomain __unused = @"PinboardDataSourceErrorDomain";

enum PINBOARD_DATA_SOURCE_ERROR_CODES {
    PinboardErrorSyncInProgress
};

@class FMResultSet;
@class PostMetadata;

@interface PinboardDataSource : NSObject <GenericPostDataSource, NSCopying>

@property (nonatomic) NSInteger totalNumberOfPosts;
@property (nonatomic, strong) NSMutableDictionary *tagsWithFrequency;
@property (nonatomic, strong) NSArray *compressedBadges;
@property (nonatomic, strong) NSArray *compressedHeights;
@property (nonatomic, strong) NSArray *compressedLinks;
@property (nonatomic, strong) NSArray *compressedStrings;
@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *enUSPOSIXDateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSMutableArray *badges;
@property (nonatomic, strong) NSMutableArray *heights;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *strings;
@property (nonatomic) BOOL shouldSearchFullText;

#pragma mark Query

@property (nonatomic) kPinboardFilterType untagged;
@property (nonatomic) kPinboardFilterType starred;
@property (nonatomic) kPinboardFilterType unread;

// private is a protected word in Objective-C
@property (nonatomic) kPinboardFilterType isPrivate;

@property (nonatomic, strong) NSArray *tags;
@property (nonatomic) NSInteger offset;
@property (nonatomic) NSInteger limit;
@property (nonatomic) NSString *orderBy;
@property (nonatomic, strong) NSString *searchQuery;

- (void)updateStarredPostsWithSuccess:(void (^)())success
                              failure:(void (^)())failure;

- (void)filterWithQuery:(NSString *)query;
- (void)filterWithParameters:(NSDictionary *)parameters;
- (void)filterByPrivate:(kPinboardFilterType)isPrivate
               isUnread:(kPinboardFilterType)isUnread
              isStarred:(kPinboardFilterType)starred
               untagged:(kPinboardFilterType)untagged
                   tags:(NSArray *)tags
                 offset:(NSInteger)offset
                  limit:(NSInteger)limit;

- (PinboardDataSource *)searchDataSource;
- (PinboardDataSource *)dataSourceWithAdditionalTag:(NSString *)tag;
- (NSArray *)quotedTags;
+ (NSDictionary *)postFromResultSet:(FMResultSet *)resultSet;

@end

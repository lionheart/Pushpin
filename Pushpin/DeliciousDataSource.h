//
//  DeliciousDataSource.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/25/14.
//
//

#import <Foundation/Foundation.h>
#import "PPConstants.h"
#import "GenericPostViewController.h"

@class FMResultSet;
@class PostMetadata;

typedef enum PPDeliciousErrorCodes {
    DeliciousErrorBookmarkNotFound,
    DeliciousErrorTimeout,
    DeliciousErrorInvalidCredentials,
    DeliciousErrorEmptyResponse
} PPDeliciousErrorCodeType;

static NSString *DeliciousDataSourceErrorDomain __unused = @"DeliciousDataSourceErrorDomain";

@interface DeliciousDataSource : NSObject <GenericPostDataSource>

@property (nonatomic) NSInteger totalNumberOfPosts;
@property (nonatomic, strong) NSMutableDictionary *tagsWithFrequency;
@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *enUSPOSIXDateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *metadata;
@property (nonatomic, strong) NSMutableArray *compressedMetadata;
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

- (void)filterWithQuery:(NSString *)query;
- (void)filterWithParameters:(NSDictionary *)parameters;
- (void)filterByUnread:(kPinboardFilterType)isUnread
              untagged:(kPinboardFilterType)untagged
                  tags:(NSArray *)tags
                offset:(NSInteger)offset
                 limit:(NSInteger)limit;

- (DeliciousDataSource *)searchDataSource;
- (DeliciousDataSource *)dataSourceWithAdditionalTag:(NSString *)tag;
- (NSArray *)quotedTags;
+ (NSDictionary *)postFromResultSet:(FMResultSet *)resultSet;

@end

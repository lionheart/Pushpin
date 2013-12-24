//
//  PinboardDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"

static NSString *kPinboardDataSourceProgressNotification __unused = @"kPinboardDataSourceProgressNotification";
static NSString *PinboardDataSourceErrorDomain __unused = @"PinboardDataSourceErrorDomain";

enum PINBOARD_DATA_SOURCE_ERROR_CODES {
    PinboardErrorSyncInProgress
};

@class FMResultSet;
@class PostMetadata;

@interface PinboardDataSource : NSObject <GenericPostDataSource>

@property (nonatomic) NSInteger maxResults;
@property (nonatomic) NSInteger totalNumberOfPosts;
@property (nonatomic, strong) NSMutableDictionary *tagsWithFrequency;
@property (nonatomic, strong) NSArray *compressedBadges;
@property (nonatomic, strong) NSArray *compressedHeights;
@property (nonatomic, strong) NSArray *compressedLinks;
@property (nonatomic, strong) NSArray *compressedStrings;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *enUSPOSIXDateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSMutableArray *badges;
@property (nonatomic, strong) NSMutableArray *heights;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *strings;
@property (nonatomic, strong) NSMutableDictionary *queryParameters;
@property (nonatomic, strong) NSString *query;

- (void)updateStarredPostsWithSuccess:(void (^)())success
                              failure:(void (^)())failure;

- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success
                                   failure:(void (^)(NSError *))failure;

- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success
                                            failure:(void (^)())failure
                                           progress:(void (^)(NSInteger, NSInteger))progress
                                            options:(NSDictionary *)options;

- (void)filterWithQuery:(NSString *)query;
- (void)filterWithParameters:(NSDictionary *)parameters;
- (void)filterByPrivate:(NSNumber *)isPrivate isRead:(NSNumber *)isRead isStarred:(NSNumber *)starred hasTags:(NSNumber *)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit;

- (PinboardDataSource *)searchDataSource;
- (PinboardDataSource *)dataSourceWithAdditionalTag:(NSString *)tag;
- (NSArray *)quotedTags;
+ (NSDictionary *)postFromResultSet:(FMResultSet *)resultSet;

- (PostMetadata *)compressedMetadataForPost:(NSDictionary *)post;
- (PostMetadata *)metadataForPost:(NSDictionary *)post;
- (PostMetadata *)metadataForPost:(NSDictionary *)post compressed:(BOOL)compressed;

- (id)initWithParameters:(NSDictionary *)parameters;

- (NSAttributedString *)stringByTrimmingTrailingPunctuationFromAttributedString:(NSAttributedString *)string offset:(NSInteger *)offset;

@end

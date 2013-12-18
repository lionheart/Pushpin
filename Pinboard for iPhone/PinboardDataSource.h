//
//  PinboardDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"
#import "FMDatabase.h"
#import "PostMetadata.h"

static NSString *kPinboardDataSourceProgressNotification __unused = @"kPinboardDataSourceProgressNotification";
static NSString *PinboardDataSourceErrorDomain __unused = @"PinboardDataSourceErrorDomain";

enum PINBOARD_DATA_SOURCE_ERROR_CODES {
    PinboardErrorSyncInProgress
};

@interface PinboardDataSource : NSObject <GenericPostDataSource>

@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, retain) NSMutableArray *posts;
@property (nonatomic, retain) NSMutableArray *heights;
@property (nonatomic, retain) NSMutableArray *strings;
@property (nonatomic, retain) NSMutableArray *links;
@property (nonatomic, retain) NSMutableArray *badges;
@property (nonatomic, strong) NSArray *compressedStrings;
@property (nonatomic, strong) NSArray *compressedHeights;
@property (nonatomic, strong) NSArray *compressedLinks;
@property (nonatomic, strong) NSArray *compressedBadges;
@property (nonatomic, retain) NSArray *urls;
@property (nonatomic) NSInteger maxResults;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;

@property (nonatomic, strong) NSString *query;
@property (nonatomic, strong) NSMutableDictionary *queryParameters;

- (void)updateStarredPostsWithSuccess:(void (^)())success failure:(void (^)())failure;
- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure;
- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success failure:(void (^)())failure progress:(void (^)(NSInteger, NSInteger))progress options:(NSDictionary *)options;
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

//
//  PinboardDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"

static NSString *kPinboardDataSourceProgressNotification = @"kPinboardDataSourceProgressNotification";

@interface PinboardDataSource : NSObject <GenericPostDataSource>

@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, retain) NSMutableArray *posts;
@property (nonatomic, retain) NSMutableArray *heights;
@property (nonatomic, retain) NSMutableArray *strings;
@property (nonatomic, retain) NSMutableArray *links;
@property (nonatomic, retain) NSArray *urls;
@property (nonatomic) NSInteger maxResults;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;

@property (nonatomic, strong) NSString *query;
@property (nonatomic, strong) NSMutableDictionary *queryParameters;

- (void)updateStarredPosts:(void (^)())success failure:(void (^)())failure;
- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure;
- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success failure:(void (^)())failure progress:(void (^)(NSInteger, NSInteger))progress options:(NSDictionary *)options;
- (void)filterWithQuery:(NSString *)query;
- (void)filterWithParameters:(NSDictionary *)parameters;
- (void)filterByPrivate:(NSNumber *)isPrivate isRead:(NSNumber *)isRead hasTags:(NSNumber *)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit;

- (PinboardDataSource *)searchDataSource;
- (PinboardDataSource *)dataSourceWithAdditionalTagID:(NSNumber *)tagID;

+ (NSArray *)linksForPost:(NSDictionary *)post;
+ (CGFloat)heightForPost:(NSDictionary *)post;

- (NSAttributedString *)attributedStringForPost:(NSDictionary *)post;
- (void)metadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *string, NSNumber *height, NSArray *links))callback;

@end

//
//  PinboardDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"


@interface PinboardDataSource : NSObject <GenericPostDataSource>

@property (nonatomic, retain) NSMutableArray *posts;
@property (nonatomic, retain) NSMutableDictionary *stringsForPosts;
@property (nonatomic, retain) NSArray *heights;
@property (nonatomic, retain) NSArray *strings;
@property (nonatomic, retain) NSArray *urls;
@property (nonatomic) NSInteger maxResults;

@property (nonatomic, strong) NSString *query;
@property (nonatomic, strong) NSMutableDictionary *queryParameters;

- (void)updateStarredPosts:(void (^)())success failure:(void (^)())failure;
- (void)updatePostsFromDatabaseWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure;
- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success failure:(void (^)())failure progress:(void (^)(NSInteger, NSInteger))progress;
- (void)filterWithQuery:(NSString *)query;
- (void)filterWithParameters:(NSDictionary *)parameters;
- (void)filterByPrivate:(BOOL)isPrivate isRead:(BOOL)isRead hasTags:(BOOL)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit;

+ (NSArray *)linksForPost:(NSDictionary *)post;
+ (CGFloat)heightForPost:(NSDictionary *)post;

@end

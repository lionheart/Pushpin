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

@property (nonatomic, retain) NSArray *posts;
@property (nonatomic, retain) NSArray *heights;
@property (nonatomic, retain) NSArray *strings;
@property (nonatomic, retain) NSArray *urls;
@property (nonatomic, retain) NSString *query;
@property (nonatomic, retain) NSDictionary *queryParameters;
@property (nonatomic) NSInteger maxResults;

- (void)filterByPrivate:(BOOL)isPrivate isRead:(BOOL)isRead isUntagged:(BOOL)isUntagged hasTags:(BOOL)hasTags tags:(NSArray *)tags offset:(NSInteger)offset limit:(NSInteger)limit;

+ (NSArray *)linksForPost:(NSDictionary *)post;
+ (CGFloat)heightForPost:(NSDictionary *)post;
+ (NSMutableAttributedString *)attributedStringForPost:(NSDictionary *)post;

@end

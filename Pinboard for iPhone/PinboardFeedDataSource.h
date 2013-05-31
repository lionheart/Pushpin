//
//  PinboardFeedDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/22/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"

@interface PinboardFeedDataSource : NSObject <GenericPostDataSource>

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSArray *components;
@property (nonatomic, retain) NSArray *heights;
@property (nonatomic, strong) NSArray *strings;
@property (nonatomic, strong) NSArray *links;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;

- (NSURL *)url;
- (id)initWithComponents:(NSArray *)components;
+ (PinboardFeedDataSource *)dataSourceWithComponents:(NSArray *)components;
+ (GenericPostViewController *)postViewControllerWithComponents:(NSArray *)components;
- (NSAttributedString *)attributedStringForPost:(NSDictionary *)post;
- (void)metadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *string, NSNumber *height, NSArray *links))callback;

@end

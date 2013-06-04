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
@property (nonatomic, strong) NSArray *heights;
@property (nonatomic, strong) NSArray *strings;
@property (nonatomic, strong) NSArray *links;
@property (nonatomic, strong) NSArray *compressedStrings;
@property (nonatomic, strong) NSArray *compressedHeights;
@property (nonatomic, strong) NSArray *compressedLinks;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSMutableArray *expandedIndices;

- (NSURL *)url;
- (id)initWithComponents:(NSArray *)components;
+ (PinboardFeedDataSource *)dataSourceWithComponents:(NSArray *)components;
+ (GenericPostViewController *)postViewControllerWithComponents:(NSArray *)components;
- (void)metadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *))callback;
- (void)compressedMetadataForPost:(NSDictionary *)post callback:(void (^)(NSAttributedString *, NSNumber *, NSArray *))callback;

@end

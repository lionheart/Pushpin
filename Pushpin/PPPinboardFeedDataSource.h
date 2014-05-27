//
//  PinboardFeedDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/22/13.
//
//

@import Foundation;

#import "PPGenericPostViewController.h"

@class PostMetadata;

static dispatch_queue_t PPPinboardFeedReloadQueue () {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.aurora.Pushpin.PinboardFeedReloadQueue", 0);
    });
    return queue;
}

@interface PPPinboardFeedDataSource : NSObject <PPDataSource>

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSArray *components;
@property (nonatomic, strong) NSArray *metadata;
@property (nonatomic, strong) NSArray *compressedMetadata;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSMutableArray *expandedIndices;
@property (nonatomic) NSInteger count;

- (NSURL *)url;
- (id)initWithComponents:(NSArray *)components;
+ (PPPinboardFeedDataSource *)dataSourceWithComponents:(NSArray *)components;
+ (PPGenericPostViewController *)postViewControllerWithComponents:(NSArray *)components;

- (NSAttributedString *)trimTrailingPunctuationFromAttributedString:(NSAttributedString *)string trimmedLength:(NSUInteger *)trimmed;

- (NSAttributedString *)stringByTrimmingTrailingPunctuationFromAttributedString:(NSAttributedString *)string offset:(NSInteger *)offset;

@end

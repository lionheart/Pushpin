//
//  GenericPostViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@protocol GenericPostDataSource <NSObject>

- (NSInteger)numberOfPosts;
- (void)updatePosts:(void (^)(NSArray *, NSArray *, NSArray *))callback;
- (CGFloat)heightForPostAtIndex:(NSInteger)index;
- (NSDictionary *)postAtIndex:(NSInteger)index;
- (NSAttributedString *)stringForPostAtIndex:(NSInteger)index;

+ (NSArray *)linksForPost:(NSDictionary *)post;
+ (CGFloat)heightForPost:(NSDictionary *)post;
+ (NSMutableAttributedString *)attributedStringForPost:(NSDictionary *)post;

@end

@interface GenericPostViewController : UITableViewController <TTTAttributedLabelDelegate>

@property (nonatomic, retain) id<GenericPostDataSource> postDataSource;

- (void)update;

@end

//
//  GenericPostViewController.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import <UIKit/UIKit.h>

@protocol GenericPostDataSource <NSObject>

- (NSArray *)posts;
- (CGFloat)heightForPostAtIndex:(NSInteger)index;
+ (NSArray *)linksForPost:(NSDictionary *)post;
+ (CGFloat)heightForPost:(NSDictionary *)post;
+ (NSMutableAttributedString *)attributedStringForPost:(NSDictionary *)post;

@end

@interface GenericPostViewController : UITableViewController

@property (nonatomic, retain) id<GenericPostDataSource> postDataSource;

@end

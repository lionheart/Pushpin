//
//  PPBadgeWrapperView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import <UIKit/UIKit.h>
#import "PPBadgeView.h"

@interface PPBadgeWrapperView : UIView

@property (nonatomic, retain) NSMutableArray *badges;
@property (nonatomic, retain) NSDictionary *badgeOptions;

- (id)initWithBadges:(NSArray *)badges;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options;
- (CGFloat)calculateHeight;

- (void)addBadgeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end

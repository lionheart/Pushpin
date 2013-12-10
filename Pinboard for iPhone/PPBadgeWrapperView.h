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
@property (nonatomic) BOOL compressed;

- (id)initWithBadges:(NSArray *)badges;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options compressed:(BOOL)compressed;
- (CGFloat)calculateHeight;

- (void)addBadgeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end

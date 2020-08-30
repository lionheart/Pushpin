//
//  PPBadgeWrapperView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

@import UIKit;

#import "PPBadgeView.h"

@class PPBadgeWrapperView;

@protocol PPBadgeWrapperDelegate <NSObject>

@optional

- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didSelectBadge:(PPBadgeView *)badge;
- (void)badgeWrapperView:(PPBadgeWrapperView *)badgeWrapperView didTapAndHoldBadge:(PPBadgeView *)badge;

@end

@interface PPBadgeWrapperView : UIView <PPBadgeDelegate>

@property (nonatomic, weak) id<PPBadgeWrapperDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *badges;
@property (nonatomic, strong) PPBadgeView *ellipsisView;
@property (nonatomic, strong) NSDictionary *badgeOptions;
@property (nonatomic) BOOL compressed;
@property (nonatomic) BOOL isInvalidated;

- (id)initWithBadges:(NSArray *)badges;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options compressed:(BOOL)compressed;
- (CGFloat)calculateHeight;
- (CGFloat)calculateHeightForWidth:(CGFloat)width;

@end

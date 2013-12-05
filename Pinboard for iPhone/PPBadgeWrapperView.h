//
//  PPBadgeWrapperView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import <UIKit/UIKit.h>

static const NSString *PPBadgeFontSize = @"fontSize";

@interface PPBadgeWrapperView : UIView

@property (nonatomic, retain) NSMutableArray *badges;
@property (nonatomic) CGFloat badgeFontSize;

- (id)initWithBadges:(NSArray *)badges;
- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options;
- (CGFloat)calculateHeight;

@end

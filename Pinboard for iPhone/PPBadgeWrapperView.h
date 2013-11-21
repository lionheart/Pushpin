//
//  PPBadgeWrapperView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import <UIKit/UIKit.h>

@interface PPBadgeWrapperView : UIView

@property (nonatomic, retain) NSMutableArray *badges;

- (id)initWithBadges:(NSArray *)badges;
- (CGFloat)calculateHeight;

@end

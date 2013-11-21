//
//  PPBadgeCollectionView.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import "PPBadgeWrapperView.h"
#import "PPBadgeView.h"

@implementation PPBadgeWrapperView

@synthesize badges = _badges;

static const CGFloat PADDING_X = 3.0f;
static const CGFloat PADDING_Y = 3.0f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithBadges:(NSArray *)badges
{
    self = [super init];
    if (self) {
        self.badges = [badges mutableCopy];
    }
    return self;
}

- (void)setBadges:(NSMutableArray *)badges {
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    
    [badges enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PPBadgeView *badgeView;
        if ([obj[@"type"] isEqualToString:@"image"]) {
            badgeView = [[PPBadgeView alloc] initWithImage:[UIImage imageNamed:obj[@"image"]]];
        } else if ([obj[@"type"] isEqualToString:@"tag"]) {
            badgeView = [[PPBadgeView alloc] initWithText:obj[@"tag"]];
        }
        [self addSubview:badgeView];
    }];
}

- (void)layoutSubviews {
    NSLog(@"layoutSubviews");
    
    CGFloat __block offsetX = 0;
    CGFloat __block offsetY = 0;
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)obj;
            CGRect frame = badgeView.frame;
            frame.origin.x = offsetX;
            offsetX += badgeView.frame.size.width + PADDING_X;
            
            if (offsetX > self.frame.size.width) {
                // Wrap to the next line
                frame.origin.y = offsetY = offsetY + badgeView.frame.size.height + PADDING_Y;
                frame.origin.x = offsetX = 0;
            }
            
            badgeView.frame = frame;
        }
    }];
}

@end

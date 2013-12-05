//
//  PPBadgeCollectionView.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import "PPBadgeWrapperView.h"
#import "PPBadgeView.h"
#import "UIApplication+AppDimensions.h"

@implementation PPBadgeWrapperView

@synthesize badges = _badges;

static const CGFloat PADDING_X = 6.0f;
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
    return [self initWithBadges:badges options:nil];
}

- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        // Defaults
        self.badgeFontSize = 10.0f;
        
        if (options) {
            if (options[PPBadgeFontSize]) {
                self.badgeFontSize = ((NSNumber *)options[PPBadgeFontSize]).floatValue;
            }
        }
        
        self.badges = [badges mutableCopy];
    }
    return self;
}

- (CGFloat)calculateHeight
{
    CGFloat __block offsetX = 0;
    CGFloat __block offsetY = 0;
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)obj;
            CGRect frame = badgeView.frame;
            offsetX += (frame.size.width + PADDING_X);
            
            if (offsetX > ([UIApplication currentSize].width - 20)) {
                offsetX = frame.size.width + PADDING_X;
                offsetY += frame.size.height + PADDING_Y;
            }
        }
    }];
    
    if (self.subviews.count > 0) {
        PPBadgeView *lastBadgeView = (PPBadgeView *)[self.subviews lastObject];
        offsetY += lastBadgeView.frame.size.height + PADDING_Y;
    }
    
    return offsetY;
}

- (void)setBadges:(NSMutableArray *)badges {
    _badges = badges;
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    
    [badges enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PPBadgeView *badgeView;
        if ([obj[@"type"] isEqualToString:@"image"]) {
            badgeView = [[PPBadgeView alloc] initWithImage:[UIImage imageNamed:obj[@"image"]]];
        } else if ([obj[@"type"] isEqualToString:@"tag"]) {
            badgeView = [[PPBadgeView alloc] initWithText:obj[@"tag"] fontSize:self.badgeFontSize];
        }
        [self addSubview:badgeView];
    }];
}

- (void)layoutSubviews {
    CGFloat __block offsetX = 0;
    CGFloat __block offsetY = 0;
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)obj;
            CGRect frame = badgeView.frame;
            frame.origin.x = offsetX;
            offsetX += (frame.size.width + PADDING_X);
            frame.origin.y = offsetY;
            
            if (offsetX > self.frame.size.width) {
                // Wrap to the next line
                offsetX = frame.size.width + PADDING_X;
                frame.origin.x = 0;
                offsetY += frame.size.height + PADDING_Y;
                frame.origin.y = offsetY;
            }
            
            badgeView.frame = frame;
        }
    }];
    
    if (self.subviews.count > 0) {
        PPBadgeView *lastBadgeView = (PPBadgeView *)[self.subviews lastObject];
        offsetY += lastBadgeView.frame.size.height + PADDING_Y;
    }
    
    CGRect frame = self.frame;
    frame.size.height = offsetY;
    self.frame = frame;
}

@end

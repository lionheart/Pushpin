//
//  PPBadgeCollectionView.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import "PPBadgeWrapperView.h"
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
        self.badgeOptions = options;
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
            NSMutableDictionary *mergedOptions = [self.badgeOptions mutableCopy];
            if (obj[@"options"]) {
                [mergedOptions addEntriesFromDictionary:obj[@"options"]];
            }
            badgeView = [[PPBadgeView alloc] initWithText:obj[@"tag"] options:mergedOptions];
        }
        [self addSubview:badgeView];
    }];
}

- (void)addBadgeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[PPBadgeView class]]) {
            [(PPBadgeView *)obj addTarget:target action:action forControlEvents:controlEvents];
        }
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

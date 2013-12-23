//
//  PPBadgeCollectionView.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import "PPBadgeWrapperView.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@implementation PPBadgeWrapperView

@synthesize badges = _badges;

static const CGFloat PADDING_X = 6;
static const CGFloat PADDING_Y = 6;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (id)initWithBadges:(NSArray *)badges {
    return [self initWithBadges:badges options:nil];
}

- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options {
    return [self initWithBadges:badges options:options compressed:NO];
}

- (id)initWithBadges:(NSArray *)badges options:(NSDictionary *)options compressed:(BOOL)compressed {
    self = [super init];
    if (self) {
        _compressed = compressed;
        self.badgeOptions = options;
        self.badges = [badges mutableCopy];
    }
    return self;
}

- (CGFloat)calculateHeight {
    if (self.badges.count == 0) {
        return 0;
    }

    if (self.compressed) {
        PPBadgeView *lastBadgeView = (PPBadgeView *)[self.subviews lastObject];
        return lastBadgeView.frame.size.height + PADDING_Y;
    }

    CGFloat offsetX = 0;
    CGFloat offsetY = 0;
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)subview;
            CGRect frame = badgeView.frame;
            offsetX += (frame.size.width + PADDING_X);
            
            if (offsetX > ([UIApplication currentSize].width - 20)) {
                offsetX = frame.size.width + PADDING_X;
                offsetY += frame.size.height + PADDING_Y;
            }
        }
    }

    if (self.subviews.count > 0) {
        PPBadgeView *lastBadgeView = (PPBadgeView *)[self.subviews lastObject];
        offsetY += lastBadgeView.frame.size.height + PADDING_Y;
    }
    
    return offsetY;
}

- (void)setBadges:(NSMutableArray *)badges {
    _badges = badges;
    
    [self lhs_removeSubviews];

    for (NSDictionary *badge in badges) {
        PPBadgeView *badgeView;
        NSMutableDictionary *mergedOptions = [self.badgeOptions mutableCopy];
        if (badge[@"options"]) {
            [mergedOptions addEntriesFromDictionary:badge[@"options"]];
        }

        if ([badge[@"type"] isEqualToString:@"image"]) {
            badgeView = [[PPBadgeView alloc] initWithImage:[UIImage imageNamed:badge[@"image"]] options:mergedOptions];
        }
        else if ([badge[@"type"] isEqualToString:@"tag"]) {
            badgeView = [[PPBadgeView alloc] initWithText:badge[@"tag"] options:mergedOptions];
        }
        [self addSubview:badgeView];
    }
}

- (void)setCompressed:(BOOL)compressed {
    _compressed = compressed;
    [self layoutSubviews];
}

- (void)addBadgeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[PPBadgeView class]]) {
            [(PPBadgeView *)subview addTarget:target action:action forControlEvents:controlEvents];
        }
    }
}

- (void)layoutSubviews {
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;

    PPBadgeView *ellipsisView = [[PPBadgeView alloc] initWithText:@"…" options:self.badgeOptions];
    CGRect ellipsisFrame = ellipsisView.frame;

    // Hide all the subviews initially.
    for (UIView *subview in self.subviews) {
        subview.hidden = YES;
    }
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)subview;
            CGRect badgeFrame = badgeView.frame;

            badgeView.hidden = NO;
            badgeFrame.origin = CGPointMake(offsetX, offsetY);
            offsetX += badgeFrame.size.width + PADDING_X;

            if (self.compressed) {
                BOOL hitsBoundaryWithEllipsis = offsetX + ellipsisFrame.size.width + PADDING_X > self.frame.size.width;
                if (hitsBoundaryWithEllipsis) {
                    // Hide the current badge and put the ellipsis in its place
                    badgeView.hidden = YES;
                    
                    [self addSubview:ellipsisView];
                    [ellipsisView addTarget:badgeView.targetTouchUpInside action:badgeView.actionTouchUpInside forControlEvents:UIControlEventTouchUpInside];
                    ellipsisView.frame = (CGRect){badgeFrame.origin, ellipsisFrame.size};
                    break;
                }
            }
            else {
                BOOL hitsBoundary = offsetX > self.frame.size.width;
                if (hitsBoundary) {
                    // Wrap to the next line
                    offsetX = badgeFrame.size.width + PADDING_X;
                    offsetY += badgeFrame.size.height + PADDING_Y;
                    
                    badgeFrame.origin = CGPointMake(0, offsetY);
                }
            }

            // Show the badge if everything has fit.
            badgeView.hidden = NO;
            badgeView.frame = badgeFrame;
        }
    }
    
    if (self.subviews.count > 0) {
        PPBadgeView *lastBadgeView = (PPBadgeView *)[self.subviews lastObject];
        offsetY += lastBadgeView.frame.size.height;
    }
    
    CGRect frame = self.frame;
    frame.size.height = offsetY;
    self.frame = frame;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.frame.size.width, [self calculateHeight]);
}

@end

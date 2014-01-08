//
//  PPBadgeCollectionView.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import "PPBadgeWrapperView.h"
#import "PPConstants.h"

#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@implementation PPBadgeWrapperView

static const CGFloat PADDING_X = 6;
static const CGFloat PADDING_Y = 6;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
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

- (CGFloat)calculateHeightForWidth:(CGFloat)width {
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;
    
    if (self.badges.count == 0) {
        return 0;
    }

    PPBadgeView *ellipsisView = [[PPBadgeView alloc] initWithText:ellipsis options:self.badgeOptions];
    CGRect ellipsisFrame = ellipsisView.frame;
    CGSize badgeSize;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)subview;
            badgeSize = badgeView.frame.size;
            offsetX += badgeSize.width + PADDING_X;

            if (self.compressed) {
                BOOL hitsBoundaryWithEllipsis = offsetX + CGRectGetWidth(ellipsisFrame) + PADDING_X > width;
                if (hitsBoundaryWithEllipsis) {
                    // Hide the current badge and put the ellipsis in its place
                    break;
                }
            }
            else {
                BOOL hitsBoundary = offsetX > width;
                if (hitsBoundary) {
                    // Wrap to the next line
                    offsetX = badgeSize.width + PADDING_X;
                    offsetY += badgeSize.height + PADDING_Y;
                }
            }
        }
    }
    
    if (self.subviews.count > 0) {
        offsetY += badgeSize.height;
    }
    
    return offsetY + PADDING_Y;
}

- (CGFloat)calculateHeight {
    return [self calculateHeightForWidth:[UIApplication currentSize].width - 20];
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
        
        badgeView.delegate = self;
        [self addSubview:badgeView];
    }
}

- (void)setCompressed:(BOOL)compressed {
    _compressed = compressed;
    [self layoutSubviews];
}

- (void)layoutSubviews {
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;

    PPBadgeView *ellipsisView = [[PPBadgeView alloc] initWithText:ellipsis options:self.badgeOptions];
    ellipsisView.delegate = self;
    CGRect ellipsisFrame = ellipsisView.frame;

    // Hide all the subviews initially.
    for (UIView *subview in self.subviews) {
        subview.hidden = YES;
    }

    CGRect badgeFrame;
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)subview;
            badgeFrame = badgeView.frame;
            badgeFrame.origin = CGPointMake(offsetX, offsetY);
            offsetX += CGRectGetWidth(badgeFrame) + PADDING_X;

            if (self.compressed) {
                BOOL hitsBoundaryWithEllipsis = offsetX + CGRectGetWidth(ellipsisFrame) + PADDING_X > CGRectGetWidth(self.frame);
                if (hitsBoundaryWithEllipsis) {
                    // Hide the current badge and put the ellipsis in its place
                    badgeView.hidden = YES;

                    [self addSubview:ellipsisView];
                    ellipsisView.frame = (CGRect){badgeFrame.origin, ellipsisFrame.size};
                    break;
                }
            }
            else {
                BOOL hitsBoundary = offsetX > CGRectGetWidth(self.frame);
                if (hitsBoundary) {
                    // Wrap to the next line
                    offsetX = CGRectGetWidth(badgeFrame) + PADDING_X;
                    offsetY += CGRectGetHeight(badgeFrame) + PADDING_Y;
                    
                    badgeFrame.origin = CGPointMake(0, offsetY);
                }
            }

            // Show the badge if everything has fit.
            badgeView.hidden = NO;
            badgeView.frame = badgeFrame;
        }
    }
    
    if (self.subviews.count > 0) {
        offsetY += CGRectGetHeight(badgeFrame);
    }
    
    CGRect frame = self.frame;
    frame.size.height = offsetY + PADDING_Y;
    self.frame = frame;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(CGRectGetWidth(self.frame), [self calculateHeightForWidth:CGRectGetWidth(self.frame)]);
}

#pragma mark - PPBadgeViewDelegate

- (void)didSelectBadgeView:(PPBadgeView *)badgeView {
    if ([self.delegate respondsToSelector:@selector(badgeWrapperView:didSelectBadge:)]) {
        [self.delegate badgeWrapperView:self didSelectBadge:badgeView];
    }
}

- (void)didTapAndHoldBadgeView:(PPBadgeView *)badgeView {
    if ([self.delegate respondsToSelector:@selector(badgeWrapperView:didTapAndHoldBadge:)]) {
        [self.delegate badgeWrapperView:self didTapAndHoldBadge:badgeView];
    }
}

@end

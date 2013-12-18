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

static const CGFloat PADDING_X = 6.0f;
static const CGFloat PADDING_Y = 3.0f;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
    if (self.compressed) {
        PPBadgeView *lastBadgeView = (PPBadgeView *)[self.subviews lastObject];
        return (lastBadgeView.frame.size.height  + PADDING_Y);
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
    BOOL hide = NO;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[PPBadgeView class]]) {
            PPBadgeView *badgeView = (PPBadgeView *)subview;
            CGRect frame = badgeView.frame;

            if (hide) {
                badgeView.hidden = YES;
            }
            else {
                badgeView.hidden = NO;
                frame.origin.x = offsetX;
                offsetX += (frame.size.width + PADDING_X);
                frame.origin.y = offsetY;
            }
            
            if (offsetX > self.frame.size.width) {
                if (self.compressed) {
                    PPBadgeView *moreBadgeView = [[PPBadgeView alloc] initWithText:@"…" options:self.badgeOptions];
                    CGRect moreFrame = moreBadgeView.frame;
                    moreFrame.origin.y = offsetY;
                    if ((offsetX + moreFrame.size.width + PADDING_X) > self.frame.size.width) {
                        // We don't have room for the more button, remove the last badge first
                        moreFrame.origin.x = offsetX - frame.size.width - PADDING_X;
                        badgeView.hidden = YES;
                        [self addSubview:moreBadgeView];
                    }
                    else {
                        moreFrame.origin.x = offsetX;
                        [self addSubview:moreBadgeView];
                    }
                    [moreBadgeView addTarget:badgeView.targetTouchUpInside action:badgeView.actionTouchUpInside forControlEvents:UIControlEventTouchUpInside];
                    moreBadgeView.frame = moreFrame;
                    offsetX = 0;
                    hide = YES;
                }
                else {
                    // Wrap to the next line
                    offsetX = frame.size.width + PADDING_X;
                    frame.origin.x = 0;
                    offsetY += frame.size.height + PADDING_Y;
                    frame.origin.y = offsetY;
                }
            }
            
            badgeView.frame = frame;
        }
    }
    
    if (self.subviews.count > 0) {
        PPBadgeView *lastBadgeView = (PPBadgeView *)[self.subviews lastObject];
        offsetY += lastBadgeView.frame.size.height + PADDING_Y;
    }
    
    CGRect frame = self.frame;
    frame.size.height = offsetY;
    self.frame = frame;
}

@end

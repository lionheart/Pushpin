//
//  PPBookmarkCell.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/26/13.
//
//

#import "PPBookmarkCell.h"
#import "GenericPostViewController.h"
#import "PPBadgeWrapperView.h"
#import "PPTheme.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@interface PPBookmarkCell ()

@property (nonatomic, strong) TTTAttributedLabel *textView;
@property (nonatomic, weak) id<GenericPostDataSource> dataSource;

@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL compressed;

@end

@implementation PPBookmarkCell

#pragma mark - Debugging Helpers

- (id)debugQuickLookObject {
    if (self.compressed && [self.dataSource respondsToSelector:@selector(compressedAttributedStringForPostAtIndex:)]) {
        return [self.dataSource compressedAttributedStringForPostAtIndex:self.index];
    }
    else {
        return [self.dataSource attributedStringForPostAtIndex:self.index];
    }
}

- (void)prepareCellWithDataSource:(id<GenericPostDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                            index:(NSInteger)index
                       compressed:(BOOL)compressed {
    
    self.index = index;
    self.compressed = compressed;

    // TODO: This is a bit of a hack, and could be updated to reuse the views
    for (UIView *subview in [self.contentView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        }
        else if ([subview isKindOfClass:[TTTAttributedLabel class]]) {
            [subview removeFromSuperview];
        }
        else if ([subview isKindOfClass:[PPBadgeWrapperView class]]) {
            [subview removeFromSuperview];
        }
    }

    NSAttributedString *string;
    if (compressed && [dataSource respondsToSelector:@selector(compressedAttributedStringForPostAtIndex:)]) {
        string = [dataSource compressedAttributedStringForPostAtIndex:index];
    }
    else {
        string = [dataSource attributedStringForPostAtIndex:index];
    }
    
    self.backgroundColor = [UIColor whiteColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.textView = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.numberOfLines = 0;
    self.textView.preferredMaxLayoutWidth = 300;
    self.textView.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.textView.linkAttributes = [NSDictionary dictionaryWithObject:@(NO) forKey:(NSString *)kCTUnderlineStyleAttributeName];
    
    NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
    [mutableActiveLinkAttributes setValue:@(NO) forKey:(NSString *)kCTUnderlineStyleAttributeName];
    [mutableActiveLinkAttributes setValue:(id)[HEX(0xeeddddff) CGColor] forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
    [mutableActiveLinkAttributes setValue:(id)@(5.0f) forKey:(NSString *)kTTTBackgroundCornerRadiusAttributeName];
    self.textView.activeLinkAttributes = mutableActiveLinkAttributes;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.userInteractionEnabled = NO;
    self.textView.text = string;
    
    [self.contentView addSubview:self.textView];
    [self.contentView lhs_addConstraints:@"H:|-10-[text]-10-|" views:@{@"text": self.textView}];
    
    NSArray *badges = [dataSource badgesForPostAtIndex:index];
    if (badges.count > 0) {
        PPBadgeWrapperView *badgeWrapperView;
        if (compressed) {
            badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) } compressed:YES];
        }
        else {
            badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) }];
        }

        badgeWrapperView.delegate = badgeDelegate;
        CGFloat height = [badgeWrapperView calculateHeightForWidth:self.contentView.bounds.size.width];
        badgeWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.contentView addSubview:badgeWrapperView];
        [self.contentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:@{@"badges": badgeWrapperView}];
        [self.contentView lhs_addConstraints:@"V:|-5-[text]-3-[badges(height)]" metrics:@{@"height": @(height)} views:@{@"text": self.textView, @"badges": badgeWrapperView }];
    }
    else {
        [self.contentView lhs_addConstraints:@"V:|-5-[text]" views:@{@"text": self.textView }];
    }
}

@end

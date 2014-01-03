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
#import "PPScrollView.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@interface PPBookmarkCell ()

@property (nonatomic, strong) TTTAttributedLabel *textView;
@property (nonatomic, weak) id<GenericPostDataSource> dataSource;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *editButton;

@property (nonatomic) BOOL didReachDeleteThreshold;
@property (nonatomic) BOOL didReachEditThreshold;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL compressed;
@property (nonatomic, strong) PPScrollView *scrollView;

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
    self.didReachDeleteThreshold = NO;
    self.didReachEditThreshold = NO;
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
    
    self.backgroundColor = [PPTheme bookmarkBackgroundColor];
    self.contentView.backgroundColor = [PPTheme bookmarkBackgroundColor];
    
    static NSDictionary *linkAttributes;
    static NSDictionary *activeLinkAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        linkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO)};
        activeLinkAttributes = @{(NSString *)kCTUnderlineStyleAttributeName: @(NO),
                                 (NSString *)kTTTBackgroundFillColorAttributeName: HEX(0xeeddddff),
                                 (NSString *)kTTTBackgroundCornerRadiusAttributeName: @(5)};
    });
    
    self.textView = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.numberOfLines = 0;
    self.textView.preferredMaxLayoutWidth = 300;
    self.textView.opaque = YES;
    self.textView.backgroundColor = [PPTheme bookmarkBackgroundColor];
    self.textView.userInteractionEnabled = NO;
    self.textView.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.textView.linkAttributes = linkAttributes;
    self.textView.activeLinkAttributes = activeLinkAttributes;
    self.textView.text = string;

    self.scrollView = [[PPScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + 1, CGRectGetHeight(self.bounds));
    self.scrollView.delegate = self;
    self.scrollView.directionalLockEnabled = YES;
    self.scrollView.backgroundColor = HEX(0xEEEEEEFF);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteButton setImage:[UIImage imageNamed:@"Delete-Button-Light"] forState:UIControlStateDisabled];
    [self.deleteButton setImage:[UIImage imageNamed:@"Delete-Button"] forState:UIControlStateNormal];
    self.deleteButton.enabled = NO;
    self.deleteButton.frame = CGRectMake(CGRectGetWidth(self.bounds) + 15, 0, 23, 23);
    CGPoint center = self.deleteButton.center;
    center.y = CGRectGetMidY(self.bounds);
    self.deleteButton.center = center;
    
    self.editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.editButton setImage:[UIImage imageNamed:@"navigation-edit-blue"] forState:UIControlStateDisabled];
    [self.editButton setImage:[UIImage imageNamed:@"navigation-edit-darker"] forState:UIControlStateNormal];
    self.editButton.enabled = NO;
    self.editButton.frame = CGRectMake(- 15 - 16, 0, 16, 20);
    center = self.deleteButton.center;
    center.y = CGRectGetMidY(self.bounds);
    self.editButton.center = center;

    UIView *mainContentView = [[UIView alloc] initWithFrame:self.bounds];
    mainContentView.backgroundColor = [UIColor whiteColor];

    [mainContentView addSubview:self.textView];
    [self.scrollView addSubview:mainContentView];
    [self.scrollView addSubview:self.deleteButton];
    [self.scrollView addSubview:self.editButton];
    [self.contentView addSubview:self.scrollView];
    
    NSDictionary *views = @{@"scroll": self.scrollView,
                            @"main": mainContentView,
                            @"text": self.textView };

    [self.contentView lhs_addConstraints:@"V:|[scroll]|" views:views];
    [self.contentView lhs_addConstraints:@"H:|[scroll]|" views:views];

    [mainContentView lhs_addConstraints:@"H:|-10-[text]-10-|" views:views];
    
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
        CGFloat height = [badgeWrapperView calculateHeightForWidth:CGRectGetWidth(self.contentView.bounds)];
        badgeWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [mainContentView addSubview:badgeWrapperView];
        [mainContentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:@{@"badges": badgeWrapperView}];
        [mainContentView lhs_addConstraints:@"V:|-5-[text]-3-[badges(height)]" metrics:@{@"height": @(height)} views:@{@"text": self.textView, @"badges": badgeWrapperView }];
    }
    else {
        [mainContentView lhs_addConstraints:@"V:|-5-[text]" views:views];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect deleteRect = self.deleteButton.frame;
    CGRect editRect = self.editButton.frame;

    CGFloat minDistance = 15;
    CGFloat threshold = 60;
    CGFloat deleteOriginalDistance = scrollView.contentSize.width + minDistance;
    CGFloat editOriginalDistance = -minDistance - 16;
    if (scrollView.contentOffset.x > threshold) {
        deleteRect.origin.x = deleteOriginalDistance + scrollView.contentOffset.x - threshold;
        self.deleteButton.enabled = YES;
    }
    else {
        deleteRect.origin.x = deleteOriginalDistance;
        self.deleteButton.enabled = NO;
    }

    if (scrollView.contentOffset.x < -threshold) {
        editRect.origin.x = editOriginalDistance + scrollView.contentOffset.x + threshold;
        self.editButton.enabled = YES;
    }
    else {
        editRect.origin.x = editOriginalDistance;
        self.editButton.enabled = NO;
    }
    
    // We reset the y coordinate as a weird side effect of the interaction with the table view pan gesture
    CGPoint point = scrollView.contentOffset;
    point.y = 0;
    scrollView.contentOffset = point;

    self.deleteButton.frame = deleteRect;
    self.editButton.frame = editRect;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.deleteButton.enabled) {
        if ([self.delegate respondsToSelector:@selector(bookmarkCellDidActivateDeleteButton:forIndex:)]) {
            [self.delegate bookmarkCellDidActivateDeleteButton:self forIndex:self.index];
        }
        self.didReachDeleteThreshold = YES;
    }
    
    if (self.editButton.enabled) {
        if ([self.delegate respondsToSelector:@selector(bookmarkCellDidActivateEditButton:forIndex:)]) {
            [self.delegate bookmarkCellDidActivateEditButton:self forIndex:self.index];
        }
        self.didReachEditThreshold = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.didReachDeleteThreshold) {
        self.didReachDeleteThreshold = NO;
    }
    
    if (self.didReachEditThreshold) {
        self.didReachEditThreshold = NO;
    }

    scrollView.contentOffset = CGPointZero;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + 1, CGRectGetHeight(self.bounds));
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.scrollView setContentOffset:CGPointZero animated:NO];
}

@end

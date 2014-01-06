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
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

static NSInteger kEditButtonInnerMargin = 15;
static NSInteger kEditButtonOuterMargin = 20;

@interface PPBookmarkCell ()

@property (nonatomic, strong) TTTAttributedLabel *textView;
@property (nonatomic, weak) id<GenericPostDataSource> dataSource;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;

@property (nonatomic) BOOL didReachDeleteThreshold;
@property (nonatomic) BOOL didReachEditThreshold;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL compressed;
@property (nonatomic, strong) NSLayoutConstraint *mainWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *leftPositionConstraint;

- (void)gestureDetected:(UIGestureRecognizer *)recognizer;

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

- (void)didTransitionToState:(UITableViewCellStateMask)state {
    [super didTransitionToState:state];

    if (state == UITableViewCellStateDefaultMask) {
        self.editButton.hidden = NO;
    }
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
    [super willTransitionToState:state];

    if (state == UITableViewCellStateEditingMask) {
        self.editButton.hidden = YES;
    }
}

- (void)prepareCellWithDataSource:(id<GenericPostDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                            index:(NSInteger)index
                       compressed:(BOOL)compressed {
    
    [self.contentView lhs_removeSubviews];
    self.contentView.clipsToBounds = YES;

    self.index = index;
    self.didReachDeleteThreshold = NO;
    self.didReachEditThreshold = NO;
    self.compressed = compressed;
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.panGestureRecognizer.delegate = self;
    [self.contentView addGestureRecognizer:self.panGestureRecognizer];

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
    self.textView.preferredMaxLayoutWidth = [UIApplication currentSize].width - 20;
    self.textView.opaque = YES;
    self.textView.backgroundColor = [PPTheme bookmarkBackgroundColor];
    self.textView.userInteractionEnabled = NO;
    self.textView.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.textView.linkAttributes = linkAttributes;
    self.textView.activeLinkAttributes = activeLinkAttributes;
    self.textView.text = string;

    self.contentView.backgroundColor = HEX(0xEEEEEEFF);

    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.deleteButton setImage:[UIImage imageNamed:@"Delete-Button-Light"] forState:UIControlStateDisabled];
    [self.deleteButton setImage:[UIImage imageNamed:@"Delete-Button"] forState:UIControlStateNormal];
    self.deleteButton.enabled = NO;
    
    self.editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.editButton setImage:[UIImage imageNamed:@"navigation-edit-blue"] forState:UIControlStateDisabled];
    [self.editButton setImage:[UIImage imageNamed:@"navigation-edit-darker"] forState:UIControlStateNormal];
    self.editButton.enabled = NO;

    UIView *mainContentView = [[UIView alloc] initWithFrame:self.bounds];
    mainContentView.translatesAutoresizingMaskIntoConstraints = NO;
    mainContentView.backgroundColor = [UIColor whiteColor];

    [mainContentView addSubview:self.textView];
    [self.contentView addSubview:mainContentView];
    [self.contentView addSubview:self.deleteButton];
    [self.contentView addSubview:self.editButton];
    
    NSDictionary *views = @{@"main": mainContentView,
                            @"edit": self.editButton,
                            @"delete": self.deleteButton,
                            @"text": self.textView };
    
    NSDictionary *metrics = @{@"innerMargin": @(kEditButtonInnerMargin),
                              @"outerMargin": @(kEditButtonOuterMargin) };
    [self.contentView lhs_centerVerticallyForView:self.deleteButton height:23];
    [self.contentView lhs_centerVerticallyForView:self.editButton height:20];
    [self.contentView lhs_addConstraints:@"H:[edit(16)]-(>=innerMargin)-[main]" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"H:[main]-(>=innerMargin)-[delete]" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"H:[delete(23)]-(<=outerMargin)-|" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"H:|-(<=outerMargin)-[edit]" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"V:|[main]|" views:views];

    self.mainWidthConstraint = [NSLayoutConstraint constraintWithItem:mainContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    self.leftPositionConstraint = [NSLayoutConstraint constraintWithItem:mainContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    
    [self.contentView addConstraints:@[self.mainWidthConstraint, self.leftPositionConstraint]];

    [mainContentView lhs_addConstraints:@"H:|-10-[text]-10-|" views:views];
    
    NSArray *badges = [dataSource badgesForPostAtIndex:index];
    if (badges.count > 0) {
        if (compressed) {
            self.badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) } compressed:YES];
        }
        else {
            self.badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) }];
        }

        self.badgeWrapperView.delegate = badgeDelegate;
        CGFloat height = [self.badgeWrapperView calculateHeightForWidth:CGRectGetWidth(self.contentView.bounds)];
        self.badgeWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [mainContentView addSubview:self.badgeWrapperView];
        [mainContentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:@{@"badges": self.badgeWrapperView}];
        [mainContentView lhs_addConstraints:@"V:|-5-[text]-3-[badges(height)]" metrics:@{@"height": @(height)} views:@{@"text": self.textView, @"badges": self.badgeWrapperView }];
    }
    else {
        [mainContentView lhs_addConstraints:@"V:|-5-[text]" views:views];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.delegate respondsToSelector:@selector(bookmarkCellCanSwipe:)]) {
        if ([self.delegate bookmarkCellCanSwipe:self]) {
            CGPoint point = [self.panGestureRecognizer locationInView:self.contentView];
            BOOL nearLeftEdgeOfScreen = point.x < 30;
            if (nearLeftEdgeOfScreen) {
                return NO;
            }

            CGPoint velocity = [self.panGestureRecognizer velocityInView:self.contentView];
            BOOL movingHorizontally = fabs(velocity.y) < fabs(velocity.x);
            return movingHorizontally;
        }
    }
    return NO;
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.panGestureRecognizer) {
        CGPoint offset = [self.panGestureRecognizer translationInView:self.contentView];
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            
            self.deleteButton.enabled = offset.x <= -(23 + kEditButtonOuterMargin + kEditButtonInnerMargin);
            self.editButton.enabled = offset.x >= (20 + kEditButtonOuterMargin + kEditButtonInnerMargin);
            
            self.leftPositionConstraint.constant = offset.x;

            [self.contentView layoutIfNeeded];
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded) {
            if (self.deleteButton.enabled) {
                if ([self.delegate respondsToSelector:@selector(bookmarkCellDidActivateDeleteButton:forIndex:)]) {
                    [self.delegate bookmarkCellDidActivateDeleteButton:self forIndex:self.index];
                }
            }
            else if (self.editButton.enabled) {
                if ([self.delegate respondsToSelector:@selector(bookmarkCellDidActivateEditButton:forIndex:)]) {
                    [self.delegate bookmarkCellDidActivateEditButton:self forIndex:self.index];
                }
            }
            
            CGFloat xVelocity = [self.panGestureRecognizer velocityInView:self.contentView].x * 1.1;
            
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.leftPositionConstraint.constant += xVelocity * 0.3;
                                 [self.contentView layoutIfNeeded];
                             }
                             completion:^(BOOL finished) {
                                 [UIView animateWithDuration:0.5
                                                  animations:^{
                                                      self.leftPositionConstraint.constant = 0;
                                                      [self.contentView layoutIfNeeded];
                                                  }];
                             }];
        }
    }
}

@end

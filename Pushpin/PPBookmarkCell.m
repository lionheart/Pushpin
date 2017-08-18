//
//  PPBookmarkCell.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/26/13.
//
//

@import TTTAttributedLabel;
@import LHSCategoryCollection;

#import "PPBookmarkCell.h"
#import "PPBadgeWrapperView.h"
#import "PPTheme.h"
#import "PPSettings.h"
#import "PPDataSource.h"

static NSInteger kEditButtonInnerMargin = 15;
static NSInteger kEditButtonOuterMargin = 20;

@interface PPBookmarkCell ()

@property (nonatomic, strong) TTTAttributedLabel *titleLabel;
@property (nonatomic, strong) TTTAttributedLabel *linkLabel;
@property (nonatomic, strong) TTTAttributedLabel *descriptionLabel;

@property (nonatomic, weak) id<PPDataSource> dataSource;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;

@property (nonatomic) BOOL didReachDeleteThreshold;
@property (nonatomic) BOOL didReachEditThreshold;
@property (nonatomic) BOOL compressed;
@property (nonatomic, strong) NSLayoutConstraint *mainWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *leftPositionConstraint;
@property (nonatomic, strong) NSDictionary *post;

- (void)gestureDetected:(UIGestureRecognizer *)recognizer;

+ (TTTAttributedLabel *)bookmarkAttributedLabelForWidth:(CGFloat)width;
- (NSDictionary *)post;

@end

@implementation PPBookmarkCell

#pragma mark - Debugging Helpers

+ (TTTAttributedLabel *)bookmarkAttributedLabelForWidth:(CGFloat)width {
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.truncationTokenStringAttributes = @{NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    label.opaque = YES;
    label.backgroundColor = [PPTheme bookmarkBackgroundColor];
    label.userInteractionEnabled = NO;
    label.numberOfLines = 0;
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    return label;
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

- (void)prepareCellWithDataSource:(id<PPDataSource>)dataSource
                    badgeDelegate:(id<PPBadgeWrapperDelegate>)badgeDelegate
                             post:(NSDictionary *)post
                       compressed:(BOOL)compressed {
    
    [self.contentView lhs_removeSubviews];
    self.contentView.clipsToBounds = YES;
    self.clipsToBounds = YES;

    self.selectionStyle = UITableViewCellSelectionStyleBlue;
    self.didReachDeleteThreshold = NO;
    self.didReachEditThreshold = NO;
    self.compressed = compressed;
    self.dataSource = dataSource;
    self.post = post;
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
    self.panGestureRecognizer.delegate = self;
    [self.contentView addGestureRecognizer:self.panGestureRecognizer];
    
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
    
    // Keeps returning invalid values. Have to hardcode.
    CGFloat width = CGRectGetWidth(self.frame) - 20;

    NSInteger index = [dataSource indexForPost:post];
    NSAttributedString *title = [dataSource titleForPostAtIndex:index];
    NSAttributedString *link = [dataSource linkForPostAtIndex:index];
    NSAttributedString *description = [dataSource descriptionForPostAtIndex:index];
    
    self.titleLabel = [PPBookmarkCell bookmarkAttributedLabelForWidth:width];
    self.titleLabel.text = title;

    self.linkLabel = [PPBookmarkCell bookmarkAttributedLabelForWidth:width];
    self.linkLabel.text = link;
    self.linkLabel.numberOfLines = 1;
    self.linkLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.descriptionLabel = [PPBookmarkCell bookmarkAttributedLabelForWidth:width];
    self.descriptionLabel.text = description;

    PostMetadata *metadata;
    if (compressed) {
        self.titleLabel.numberOfLines = 1;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        self.descriptionLabel.numberOfLines = 2;
        self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        metadata = [dataSource compressedMetadataForPostAtIndex:index];
    } else {
        metadata = [dataSource metadataForPostAtIndex:index];
    }

    BOOL read;
    if (self.post[@"unread"]) {
        read = ![self.post[@"unread"] boolValue];
    } else {
        read = NO;
    }

    BOOL dimmed = [PPSettings sharedSettings].dimReadPosts && read;

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
    
    if (self.isEditing) {
        self.editButton.hidden = YES;
        self.deleteButton.hidden = YES;
    } else {
        self.editButton.hidden = NO;
        self.deleteButton.hidden = NO;
    }

    UIView *mainContentView = [[UIView alloc] initWithFrame:self.bounds];
    mainContentView.translatesAutoresizingMaskIntoConstraints = NO;
    mainContentView.backgroundColor = [UIColor whiteColor];

    [self.titleLabel sizeToFit];
    [self.linkLabel sizeToFit];
    [self.descriptionLabel sizeToFit];

    [mainContentView addSubview:self.titleLabel];
    [mainContentView addSubview:self.linkLabel];
    [mainContentView addSubview:self.descriptionLabel];

    [self.contentView addSubview:mainContentView];
    [self.contentView addSubview:self.deleteButton];
    [self.contentView addSubview:self.editButton];
    
    NSMutableDictionary *views = [@{@"main": mainContentView,
                                    @"edit": self.editButton,
                                    @"delete": self.deleteButton,
                                    @"title": self.titleLabel,
                                    @"description": self.descriptionLabel,
                                    @"link": self.linkLabel } mutableCopy];
    
    NSDictionary *metrics = @{@"innerMargin": @(kEditButtonInnerMargin),
                              @"outerMargin": @(kEditButtonOuterMargin) };

    [self.contentView lhs_centerVerticallyForView:self.deleteButton height:23];
    [self.contentView lhs_centerVerticallyForView:self.editButton height:20];
    [self.contentView lhs_addConstraints:@"H:[edit(16)]-(>=innerMargin)-[main]" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"H:[main]-(>=innerMargin)-[delete]" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"H:[delete(23)]-(<=outerMargin)-|" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"H:|-(<=outerMargin)-[edit]" metrics:metrics views:views];
    [self.contentView lhs_addConstraints:@"V:|[main]|" views:views];

    self.mainWidthConstraint = [NSLayoutConstraint constraintWithItem:mainContentView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.contentView
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:1
                                                             constant:0];
    self.leftPositionConstraint = [NSLayoutConstraint constraintWithItem:mainContentView
                                                               attribute:NSLayoutAttributeLeft
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.contentView
                                                               attribute:NSLayoutAttributeLeft
                                                              multiplier:1
                                                                constant:0];
    
    [self.contentView addConstraints:@[self.mainWidthConstraint, self.leftPositionConstraint]];

    [mainContentView lhs_addConstraints:@"H:|-10-[title]-10-|" views:views];
    [mainContentView lhs_addConstraints:@"H:|-10-[link]-10-|" views:views];
    [mainContentView lhs_addConstraints:@"H:|-10-[description]-10-|" views:views];
    
    NSMutableDictionary *postMetrics = [@{@"titleHeight": @(metadata.titleHeight + 1),
                                          @"descriptionHeight": @(metadata.descriptionHeight + 1),
                                          @"linkHeight": @(metadata.linkHeight + 1) } mutableCopy];

    NSArray *badges = [dataSource badgesForPostAtIndex:index];
    if (badges.count > 0) {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[PPBadgeFontSize] = @([PPTheme badgeFontSize]);
        if (dimmed) {
            options[PPBadgeNormalBackgroundColor] = HEX(0xDDDDDDFF);
        }

        if (compressed) {
            self.badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:options compressed:YES];
        } else {
            self.badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:options];
        }

        views[@"badges"] = self.badgeWrapperView;

        self.badgeWrapperView.tag = index;
        self.badgeWrapperView.delegate = badgeDelegate;
        CGFloat height = [self.badgeWrapperView calculateHeightForWidth:width];
        self.badgeWrapperView.translatesAutoresizingMaskIntoConstraints = NO;
        
        postMetrics[@"badgeHeight"] = @(height);
        [mainContentView addSubview:self.badgeWrapperView];
        [mainContentView lhs_addConstraints:@"H:|-10-[badges]-10-|" views:views];
        [mainContentView lhs_addConstraints:@"V:|-5-[title(titleHeight)][link(linkHeight)][description(descriptionHeight)]-5-[badges(badgeHeight)]" metrics:postMetrics views:views];
    } else {
        [mainContentView lhs_addConstraints:@"V:|-5-[title(titleHeight)][link(linkHeight)][description(descriptionHeight)]" metrics:postMetrics views:views];
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

            CGFloat maxOffset = CGFLOAT_MAX;
            if ([self.delegate respondsToSelector:@selector(bookmarkCellMaxHorizontalOffset)]) {
                maxOffset = [self.delegate bookmarkCellMaxHorizontalOffset];
            }

            self.leftPositionConstraint.constant = (offset.x > 0 ? 1 : -1) * MIN(maxOffset, ABS(offset.x));;

            if ([self.delegate respondsToSelector:@selector(bookmarkCellDidScroll:)]) {
                [self.delegate bookmarkCellDidScroll:offset];
            }

            [self.contentView layoutIfNeeded];
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded) {
            if (self.deleteButton.enabled) {
                if ([self.delegate respondsToSelector:@selector(bookmarkCellDidActivateDeleteButton:forPost:)]) {
                    [self.delegate bookmarkCellDidActivateDeleteButton:self
                                                               forPost:self.post];
                }
            }
            else if (self.editButton.enabled) {
                if ([self.delegate respondsToSelector:@selector(bookmarkCellDidActivateEditButton:forPost:)]) {
                    [self.delegate bookmarkCellDidActivateEditButton:self
                                                             forPost:self.post];
                }
            }

            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.leftPositionConstraint.constant = 0;
                                 [self.contentView layoutIfNeeded];
                             }];
        }
    }
}

- (NSString *)accessibilityLabel {
    return [NSString stringWithFormat:@"%@, %@, %@", self.titleLabel.text, self.linkLabel.text, self.descriptionLabel.text];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setSelectedBackgroundView:(UIView *)selectedBackgroundView {
    [super setSelectedBackgroundView:selectedBackgroundView];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:NO animated:animated];
    [self setNeedsLayout];
}

@end

//
//  PPTitleButton.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

#import "PPTitleButton.h"
#import "PPTheme.h"
#import <LHSCategoryCollection/UIView+LHSAdditions.h>

@interface PPTitleButton ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) NSMutableArray *existingConstraints;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)addConstraintsForImageAndTitle;
- (void)addConstraintsForTitleOnly;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;

@end

@implementation PPTitleButton

- (instancetype)initWithDelegate:(id<PPTitleButtonDelegate>)delegate {
    self = [super initWithFrame:CGRectMake(0, 0, 300, 24)];
    if (self) {
        self.containerView = [[UIView alloc] init];
        self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.centerView = [[UIView alloc] init];
        self.centerView.translatesAutoresizingMaskIntoConstraints = NO;

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.clipsToBounds = YES;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.adjustsFontSizeToFitWidth = NO;
        self.titleLabel.font = [PPTheme extraLargeFont];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.centerView addSubview:self.titleLabel];
        
        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.subtitleLabel.font = [UIFont fontWithName:[PPTheme fontName] size:12];
        self.subtitleLabel.textColor = [UIColor whiteColor];
        self.subtitleLabel.text = @"◍";
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        [self.containerView addSubview:self.subtitleLabel];
        
        self.imageView = [[UIImageView alloc] init];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.centerView addSubview:self.imageView];
        
        [self addSubview:self.containerView];
        [self.containerView addSubview:self.centerView];

        [self lhs_centerVerticallyForView:self.containerView];
        [self lhs_centerHorizontallyForView:self.containerView];
        [self addConstraintsForImageAndTitle];
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDetected:)];
        [self addGestureRecognizer:self.tapGestureRecognizer];
        
        self.delegate = delegate;
    }
    return self;
}

+ (instancetype)buttonWithDelegate:(id)delegate {
    return [[PPTitleButton alloc] initWithDelegate:delegate];
}

+ (instancetype)button {
    return [[PPTitleButton alloc] initWithDelegate:nil];
}

- (void)setTitle:(NSString *)title imageName:(NSString *)imageName {
    self.titleLabel.text = title;

    if (imageName) {
        self.imageView.image = [UIImage imageNamed:imageName];
        [self addConstraintsForImageAndTitle];
    }
    else {
        self.imageView.image = nil;
        [self addConstraintsForTitleOnly];
    }
    
    NSDictionary *views = @{@"subtitle": self.subtitleLabel };
    [self.containerView lhs_addConstraints:@"H:|[subtitle]|" views:views];
    [self.containerView lhs_centerHorizontallyForView:self.centerView];

    [self layoutIfNeeded];
    self.frame = (CGRect){{0, 0}, self.containerView.frame.size};
}

- (void)addConstraintsForImageAndTitle {
    NSDictionary *views = @{@"title": self.titleLabel,
                            @"image": self.imageView,
                            @"subtitle": self.subtitleLabel,
                            @"center": self.centerView };

    [self.centerView removeConstraints:self.centerView.constraints];
    [self.centerView lhs_addConstraints:@"H:|[image(20)]-5-[title(<=215)]|" views:views];
    [self.centerView lhs_centerVerticallyForView:self.imageView height:20];
    [self.centerView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.centerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:1]];
    
    [self.containerView removeConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"V:|[center][subtitle]|" views:views];
}

- (void)addConstraintsForTitleOnly {
    NSDictionary *views = @{@"title": self.titleLabel,
                            @"subtitle": self.subtitleLabel,
                            @"center": self.centerView };

    [self.centerView removeConstraints:self.centerView.constraints];
    [self.centerView lhs_addConstraints:@"H:|[title(<=240)]|" views:views];
    [self.centerView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.centerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:1]];

    [self.containerView removeConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"V:|-8-[center]-8-[subtitle]|" views:views];
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.tapGestureRecognizer) {
        if (self.delegate) {
            [self.delegate titleButtonTouchUpInside:self];
        }
    }
}

@end

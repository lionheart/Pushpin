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
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface PPTitleButton ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) NSMutableArray *existingConstraints;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)addConstraintsForImageOnly;
- (void)addConstraintsForImageAndTitle;
- (void)addConstraintsForTitleOnly;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;

@end

@implementation PPTitleButton

+ (instancetype)buttonWithDelegate:(id)delegate {
    PPTitleButton *titleButton = [[PPTitleButton alloc] init];
    titleButton.frame = CGRectMake(0, 0, [UIApplication currentSize].width - 20, 24);
    titleButton.containerView = [[UIView alloc] init];
    titleButton.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    titleButton.titleLabel = [[UILabel alloc] init];
    titleButton.titleLabel.clipsToBounds = YES;
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.titleLabel.adjustsFontSizeToFitWidth = NO;
    titleButton.titleLabel.font = [PPTheme extraLargeFont];
    titleButton.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleButton.containerView addSubview:titleButton.titleLabel];
    
    titleButton.imageView = [[UIImageView alloc] init];
    titleButton.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [titleButton.containerView addSubview:titleButton.imageView];
    
    [titleButton addSubview:titleButton.containerView];
    [titleButton lhs_centerVerticallyForView:titleButton.containerView];
    [titleButton lhs_centerHorizontallyForView:titleButton.containerView];
    [titleButton addConstraintsForImageAndTitle];
    
    titleButton.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:titleButton action:@selector(gestureDetected:)];
    [titleButton addGestureRecognizer:titleButton.tapGestureRecognizer];
    
    titleButton.delegate = delegate;
    return titleButton;
}

+ (instancetype)button {
    return [PPTitleButton buttonWithDelegate:nil];
}

- (void)setTitle:(NSString *)title imageName:(NSString *)imageName {
    if (imageName) {
        self.imageView.image = [UIImage imageNamed:imageName];

        if (title) {
            self.titleLabel.text = title;
            [self addConstraintsForImageAndTitle];
        }
        else {
            [self addConstraintsForImageOnly];
        }
    }
    else {
        self.titleLabel.text = title;
        self.imageView.image = nil;
        [self addConstraintsForTitleOnly];
    }

    [self layoutIfNeeded];
    self.frame = (CGRect){{0, 0}, self.containerView.frame.size};
}

- (void)addConstraintsForImageAndTitle {
    NSDictionary *views = @{@"title": self.titleLabel,
                            @"image": self.imageView};

    NSDictionary *metrics = @{@"width": @([UIApplication currentSize].width - 120)};

    [self.containerView removeConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[image(20)]-5-[title(<=width)]|" metrics:metrics views:views];
    [self.containerView lhs_centerVerticallyForView:self.imageView height:20];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:1]];
}

- (void)addConstraintsForTitleOnly {
    NSDictionary *views = @{@"title": self.titleLabel};
    NSDictionary *metrics = @{@"width": @([UIApplication currentSize].width - 95)};

    [self.containerView removeConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[title(<=width)]|" metrics:metrics views:views];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:1]];
}

- (void)addConstraintsForImageOnly {
    NSDictionary *views = @{@"image": self.imageView};
    NSDictionary *metrics = @{@"width": @(30)};

    [self.containerView removeConstraints:self.containerView.constraints];
    [self.containerView lhs_addConstraints:@"H:|[image(width)]|" metrics:metrics views:views];
    [self.containerView lhs_addConstraints:@"V:|[image(width)]|" metrics:metrics views:views];
}

- (void)gestureDetected:(UIGestureRecognizer *)recognizer {
    if (recognizer == self.tapGestureRecognizer) {
        if (self.delegate) {
            [self.delegate titleButtonTouchUpInside:self];
        }
    }
}

@end

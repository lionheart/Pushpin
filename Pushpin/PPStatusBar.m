//
//  PPStatusBar.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/12/14.
//
//

#import "PPStatusBar.h"
#import "AddBookmarkViewController.h"
#import "PPNavigationController.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIViewController+LHSAdditions.h>

@interface PPStatusBar ()

@property (nonatomic) BOOL hidden;
@property (nonatomic, strong) UIView *superview;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)hide;

@end

@implementation PPStatusBar

+ (instancetype)status {
    return [[[self class] alloc] init];
}

- (void)showWithText:(NSString *)text {
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    self.tapGestureRecognizer.numberOfTapsRequired = 1;

    UIViewController *controller = [UIViewController lhs_topViewController];
    if ([[controller class] isEqual:[AddBookmarkViewController class]]) {
        controller = (UIViewController *)[[PPAppDelegate sharedDelegate].navigationController topViewController];
    }

    self.superview = controller.view;
    if ([[self.superview class] isSubclassOfClass:[UITableView class]]) {
        self.superview = [PPAppDelegate sharedDelegate].window;
    }

    self.view = [[UIView alloc] init];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];

    NSInteger numWords = [[text componentsSeparatedByString:@" "] count];
    NSInteger averageWordsPerMinute = 225;
    CGFloat minutesNeededToRead = (CGFloat)numWords / (CGFloat)averageWordsPerMinute;
    CGFloat secondsNeededToRead = minutesNeededToRead * 60;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor whiteColor];
    label.textColor = HEX(0x777777FF);
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];
    
    UIView *border = [[UIView alloc] init];
    border.translatesAutoresizingMaskIntoConstraints = NO;
    border.backgroundColor = HEX(0xD6D6D6FF);
    [self.view addSubview:border];

    NSDictionary *views = @{@"view": self.view,
                            @"label": label,
                            @"border": border };

    [self.view lhs_addConstraints:@"H:|-10-[label]-10-|" views:views];
    
    if (controller.navigationController.navigationBarHidden) {
        [self.view lhs_addConstraints:@"V:|-52-[label]-10-|" views:views];
    }
    else {
        [self.view lhs_addConstraints:@"V:|-30-[label]-10-|" views:views];
    }

    [self.view lhs_addConstraints:@"H:|[border]|" views:views];
    [self.view lhs_addConstraints:@"V:[border(1)]|" views:views];

    [self.superview addSubview:self.view];
    [self.superview lhs_addConstraints:@"H:|[view]|" views:views];
    [self.superview layoutIfNeeded];

    CGFloat height = CGRectGetHeight(self.view.frame) + 20;
    self.topConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:controller.view attribute:NSLayoutAttributeTop multiplier:1 constant:-height];
    [self.superview addConstraint:self.topConstraint];
    [self.superview layoutIfNeeded];

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         self.topConstraint.constant = -20;
                         [self.superview layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         double delayInSeconds = secondsNeededToRead;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             [self hide];
                         });
                     }];
}

- (void)hide {
    if (!self.hidden) {
        self.hidden = YES;

        CGFloat height = CGRectGetHeight(self.view.frame) + 20;
        [UIView animateWithDuration:0.1
                         animations:^{
                             self.topConstraint.constant = -10;
                             [self.superview layoutIfNeeded];
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.2 animations:^{
                                 self.topConstraint.constant = -height;
                                 [self.superview layoutIfNeeded];
                             }];
                         }];
    }
}

@end

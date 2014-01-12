//
//  PPStatusBar.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/12/14.
//
//

#import "PPStatusBar.h"
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIViewController+LHSAdditions.h>

@interface PPStatusBar ()

@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;

- (void)hide;

@end

@implementation PPStatusBar

+ (instancetype)status {
    return [[[self class] alloc] init];
}

- (void)showWithText:(NSString *)text {
    UIViewController *controller = [UIViewController lhs_topViewController];
    
    self.view = [[UIView alloc] init];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor whiteColor];
    label.textColor = HEX(0x777777FF);
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
    [self.view lhs_addConstraints:@"V:|-10-[label]-10-|" views:views];
    [self.view lhs_addConstraints:@"H:|[border]|" views:views];
    [self.view lhs_addConstraints:@"V:[border(1)]|" views:views];

    [controller.view addSubview:self.view];
    [controller.view lhs_addConstraints:@"H:|[view]|" views:views];
    [controller.view layoutIfNeeded];

    self.topConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationLessThanOrEqual toItem:controller.view attribute:NSLayoutAttributeTop multiplier:1 constant:-CGRectGetHeight(self.view.frame)];
    [controller.view addConstraint:self.topConstraint];
    [controller.view layoutIfNeeded];

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         self.topConstraint.constant = 0;
                         [controller.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         double delayInSeconds = 1.5;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             [UIView animateWithDuration:0.3
                                              animations:^{
                                                  self.topConstraint.constant = -CGRectGetHeight(self.view.frame);
                                                  [controller.view layoutIfNeeded];
                                              }];
                         });
                     }];
}

@end

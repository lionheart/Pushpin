//
//  RDActionSheet.m
//  RDActionSheet v1.1.0
//
//  Created by Red Davis on 12/01/2012.
//  Copyright (c) 2012 Riot. All rights reserved.
//

#import "RDActionSheet.h"
#import "PPButton.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "UIApplication+AppDimensions.h"
#import "UIApplication+Additions.h"

@interface RDActionSheet ()

@property (nonatomic, strong) UIView *blackOutView;
@property (nonatomic, strong) UILabel *titleLabel;

- (void)setupButtons;
- (void)setupBackground;
- (UIView *)buildBlackOutViewWithFrame:(CGRect)frame;

- (PPButton *)buildButtonWithTitle:(NSString *)title;
- (PPButton *)buildCancelButtonWithTitle:(NSString *)title;
- (PPButton *)buildPrimaryButtonWithTitle:(NSString *)title;
- (PPButton *)buildDestroyButtonWithTitle:(NSString *)title;

- (CGFloat)calculateSheetHeight;

- (void)buttonWasPressed:(id)button;

@end


const CGFloat kButtonPadding = 10;
const CGFloat kButtonHeight = 47;

const CGFloat kPortraitButtonWidth = 300;
const CGFloat kLandscapeButtonWidth = 450;

const CGFloat kActionSheetAnimationTime = 0.2;
const CGFloat kBlackoutViewFadeInOpacity = 0.6;


@implementation RDActionSheet

@synthesize delegate;
@synthesize callbackBlock;

@synthesize buttons;
@synthesize blackOutView;

#pragma mark - Initialization

- (id)init { 
    self = [super init];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.buttons = [NSMutableArray array];
        self.opaque = YES;
    }
    
    return self;
}

- (id)initWithDelegate:(NSObject<RDActionSheetDelegate> *)aDelegate cancelButtonTitle:(NSString *)cancelButtonTitle primaryButtonTitle:(NSString *)primaryButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    
    self = [self initWithCancelButtonTitle:cancelButtonTitle primaryButtonTitle:primaryButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:otherButtonTitles, nil];
    
    if (self) {
        self.delegate = aDelegate;
    }

    return self;
}

- (id)initWithCancelButtonTitle:(NSString *)cancelButtonTitle primaryButtonTitle:(NSString *)primaryButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitleArray:(NSArray *)otherButtonTitleArray {
    self = [self init];
    if (self) {
        // Build normal buttons
        for (NSString *title in otherButtonTitleArray) {
            PPButton *button = [self buildButtonWithTitle:title];
            [self.buttons insertObject:button atIndex:0];
        }
        
        // Build cancel button
        PPButton *cancelButton = [self buildCancelButtonWithTitle:cancelButtonTitle];
        [self.buttons insertObject:cancelButton atIndex:0];
        
        // Add primary button
        if (primaryButtonTitle) {
            PPButton *primaryButton = [self buildPrimaryButtonWithTitle:primaryButtonTitle];
            [self.buttons addObject:primaryButton];
        }
        
        // Add destroy button
        if (destructiveButtonTitle) {
            PPButton *destroyButton = [self buildDestroyButtonWithTitle:destructiveButtonTitle];
            [self.buttons insertObject:destroyButton atIndex:1];
        }
    }
    
    return self;
}

- (void)addButtonWithTitle:(NSString *)title {
    PPButton *button = [self buildButtonWithTitle:title];
    [self.buttons addObject:button];
}

- (id)initWithCancelButtonTitle:(NSString *)cancelButtonTitle primaryButtonTitle:(NSString *)primaryButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {

    va_list titles;
    va_start(titles, otherButtonTitles);
    NSMutableArray *otherButtonTitleArray = [NSMutableArray array];
    NSString *arg = otherButtonTitles;
    while (arg != nil) {
        [otherButtonTitleArray addObject:arg];
        arg = va_arg(titles, NSString *);
    }
    
    va_end(titles);

    self = [self initWithCancelButtonTitle:cancelButtonTitle primaryButtonTitle:primaryButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitleArray:otherButtonTitleArray];
    
    return self;
}

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle primaryButtonTitle:(NSString *)primaryButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSArray *)otherButtonTitleList {
    self = [self initWithCancelButtonTitle:cancelButtonTitle primaryButtonTitle:primaryButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitleArray:otherButtonTitleList];
    
	if ([title length]) {
		_titleLabel = [self buildTitleLabelWithTitle:title];
	}
    
    return self;
}

- (id)initWithTitle:(NSString *)title delegate:(NSObject <RDActionSheetDelegate> *)aDelegate cancelButtonTitle:(NSString *)cancelButtonTitle primaryButtonTitle:(NSString *)primaryButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitleArray:(NSArray *)otherButtonTitles {
    self = [self initWithCancelButtonTitle:cancelButtonTitle primaryButtonTitle:primaryButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitleArray:otherButtonTitles];
    
	if ([title length]) {
		_titleLabel = [self buildTitleLabelWithTitle:title];
	}
	if (aDelegate) {
		self.delegate = aDelegate;
	}
    
    return self;
}

- (id)initWithTitle:(NSString *)title delegate:(NSObject <RDActionSheetDelegate> *)aDelegate cancelButtonTitle:(NSString *)cancelButtonTitle primaryButtonTitle:(NSString *)primaryButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    va_list titles;
    va_start(titles, otherButtonTitles);
    NSMutableArray *otherButtonTitleArray = [NSMutableArray array];
    NSString *arg = otherButtonTitles;
    while (arg != nil) {
        [otherButtonTitleArray addObject:arg];
        arg = va_arg(titles, NSString *);
    }
    
    va_end(titles);
    
    self = [self initWithCancelButtonTitle:cancelButtonTitle primaryButtonTitle:primaryButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitleArray:otherButtonTitleArray];
    
	if ([title length]) {
		_titleLabel = [self buildTitleLabelWithTitle:title];
	}
	if (aDelegate) {
		self.delegate = aDelegate;
	}
    
    return self;
}

#pragma mark - View setup

- (void)layoutSubviews {
    
    [self setupBackground];
    [self setupTitle];
    [self setupButtons];
}

- (void)setupBackground {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.frame.size.width, self.frame.size.height), YES, 0);
    CGContextRef con = UIGraphicsGetCurrentContext();
    
    // http://stackoverflow.com/questions/1303855/how-to-draw-a-gradient-line-fading-in-out-with-core-graphics-iphone
    CGColorSpaceRef myColorspace=CGColorSpaceCreateDeviceRGB();
    size_t num_locations = 2;
    CGFloat locations[2] = { 1.0, 0.0 };
    CGFloat components[8] =	{ 0.129, 0.141, 0.173, 1.0, 0.29, 0.31, 0.361, 1.0 };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
    CGPoint startPoint, endPoint;
    startPoint.x = 0.0;
    startPoint.y = 0.0;
    endPoint.x = 0.0;
    endPoint.y = self.frame.size.height;
    
    CGContextSaveGState(con);
    CGContextAddRect(con, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
    CGContextClip(con);
    CGContextDrawLinearGradient(con, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(con);
    
    // Draw top line
    CGContextBeginPath(con);
    CGContextSetStrokeColorWithColor(con, HEX(0x13151Bff).CGColor);
    CGContextSetLineWidth(con, 1);
    CGContextMoveToPoint(con, 0, 0);
    CGContextAddLineToPoint(con, self.frame.size.width, 0);
    CGContextStrokePath(con);
    
    // Draw inset line
    CGContextBeginPath(con);
    CGContextSetStrokeColorWithColor(con, HEX(0x788098ff).CGColor);
    CGContextSetLineWidth(con, 1);
    CGContextMoveToPoint(con, 0, 1);
    CGContextAddLineToPoint(con, self.frame.size.width, 1);
    CGContextStrokePath(con);

    // Draw Line
    CGFloat lineYAxis = self.frame.size.height - (kButtonPadding * 2 + kButtonHeight);

    CGContextBeginPath(con);
    CGContextSetStrokeColorWithColor(con, HEX(0x13151Bff).CGColor);
    CGContextSetLineWidth(con, 1);
    CGContextMoveToPoint(con, 0, lineYAxis);
    CGContextAddLineToPoint(con, self.frame.size.width, lineYAxis);
    CGContextStrokePath(con);
    
    // Draw inset line
    CGContextBeginPath(con);
    CGContextSetStrokeColorWithColor(con, HEX(0x5C6478ff).CGColor);
    CGContextSetLineWidth(con, 1);
    CGContextMoveToPoint(con, 0, lineYAxis + 1);
    CGContextAddLineToPoint(con, self.frame.size.width, lineYAxis + 1);
    CGContextStrokePath(con);

    UIImage *finishedBackground = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *background = [[UIImageView alloc] initWithImage:finishedBackground];
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self insertSubview:background atIndex:0];
}

- (void)setupButtons {
    
    CGFloat yOffset = self.frame.size.height - kButtonPadding - floorf(kButtonHeight/2);
    
    BOOL cancelButton = YES;
    for (PPButton *button in self.buttons) {
        CGFloat buttonWidth;
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        BOOL isIPad = [UIApplication isIPad];
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
            if (isIPad) {
                buttonWidth = [UIApplication currentSize].width - 20;
            }
            else {
                buttonWidth = kLandscapeButtonWidth;
            }
        } 
        else {
            if (isIPad) {
                buttonWidth = [UIApplication currentSize].width - 45;
            }
            else {
                buttonWidth = kPortraitButtonWidth;
            }
        }
        
        button.frame = CGRectMake(0, 0, buttonWidth, kButtonHeight);
        button.center = CGPointMake(self.center.x, yOffset);
        [self addSubview:button];
        
        yOffset -= button.frame.size.height + kButtonPadding;
        
        // We draw a line above the cancel button so add an extra kButtonPadding
        if (cancelButton) {
            yOffset -= kButtonPadding;
            cancelButton = NO;
        }
    }
}

- (void)setupTitle {
    
    CGFloat labelWidth;
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    BOOL isIPad = [UIApplication isIPad];
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
        if (isIPad) {
            labelWidth = [UIApplication currentSize].width - 20;
        }
        else {
            labelWidth = kLandscapeButtonWidth;
        }
    }
    else {
        if (isIPad) {
            labelWidth = [UIApplication currentSize].width - 45;
        }
        else {
            labelWidth = kPortraitButtonWidth;
        }
    }
    
    self.titleLabel.frame = CGRectMake((self.bounds.size.width - labelWidth) / 2, self.titleLabel.frame.origin.y, labelWidth, self.titleLabel.bounds.size.height);
    
    [self addSubview:self.titleLabel];
}

#pragma mark - Blackout view builder

- (UIView *)buildBlackOutViewWithFrame:(CGRect)frame {
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor blackColor];
    view.opaque = YES;
    view.alpha = 0;
    
    return view;
}

#pragma mark - Button builders

- (UILabel *)buildTitleLabelWithTitle:(NSString *)title {
    CGSize newSize = [title sizeWithFont:[UIFont fontWithName:[AppDelegate heavyFontName] size:13.0]
                            constrainedToSize:CGSizeMake([UIApplication currentSize].width - 20, NSIntegerMax)
                                lineBreakMode:NSLineBreakByWordWrapping];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 9.0, [UIApplication currentSize].width - 20, newSize.height + 5.0)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:13.0];
    label.numberOfLines = 0;
    label.text = title;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    label.shadowOffset = CGSizeMake(0.0, -1.0);
    return label;
}

- (PPButton *)buildButtonWithTitle:(NSString *)title {
    PPButton *button = [[PPButton alloc] init];
    [button addTarget:self action:@selector(buttonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    button.accessibilityLabel = title;
    return button;
}

- (PPButton *)buildCancelButtonWithTitle:(NSString *)title {
    return [self buildButtonWithTitle:title];
}

- (PPButton *)buildPrimaryButtonWithTitle:(NSString *)title {
    return [self buildButtonWithTitle:title];
}

- (PPButton *)buildDestroyButtonWithTitle:(NSString *)title {
    return [self buildButtonWithTitle:title];
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex {
    return [[[self.buttons objectAtIndex:buttonIndex] titleLabel] text];
}

#pragma mark - Button actions

- (void)buttonWasPressed:(id)button {
    NSInteger buttonIndex = [self.buttons indexOfObject:button];
    
    if (self.callbackBlock) {
        self.callbackBlock(RDActionSheetCallbackTypeClickedButtonAtIndex, buttonIndex, [[[self.buttons objectAtIndex:buttonIndex] titleLabel] text]);
    }
    else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
            [self.delegate actionSheet:self clickedButtonAtIndex:buttonIndex];
        }
    }
    
    [self hideActionSheetWithButtonIndex:buttonIndex];
}

- (void)hideActionSheetWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex >= 0) {
        if (self.callbackBlock) {
            self.callbackBlock(RDActionSheetCallbackTypeWillDismissWithButtonIndex, buttonIndex, [[[self.buttons objectAtIndex:buttonIndex] titleLabel] text]);
        }
        else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)]) {
                [self.delegate actionSheet:self willDismissWithButtonIndex:buttonIndex];
            }
        }
    }
    [UIView animateWithDuration:kActionSheetAnimationTime animations:^{
        CGFloat endPosition = self.frame.origin.y + self.frame.size.height;
        self.frame = CGRectMake(self.frame.origin.x, endPosition, self.frame.size.width, self.frame.size.height);
        self.blackOutView.alpha = 0;
    } completion:^(BOOL finished) {
        if (buttonIndex >= 0) {
            if (self.callbackBlock) {
                self.callbackBlock(RDActionSheetCallbackTypeDidDismissWithButtonIndex, buttonIndex, [[[self.buttons objectAtIndex:buttonIndex] titleLabel] text]);
            }
            else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)]) {
                    [self.delegate actionSheet:self didDismissWithButtonIndex:buttonIndex];
                }
            }
        }
        [self removeFromSuperview];
    }];
}

-(void)cancelActionSheet {
    [self hideActionSheetWithButtonIndex:-1];
}

#pragma mark - Present action sheet

- (void)showFrom:(UIView *)view {
        
    CGFloat startPosition = view.bounds.origin.y + view.bounds.size.height;
    self.frame = CGRectMake(0, startPosition, view.bounds.size.width, [self calculateSheetHeight]);
    [view addSubview:self];
        
    self.blackOutView = [self buildBlackOutViewWithFrame:view.bounds];
    [view insertSubview:self.blackOutView belowSubview:self];
    
    if (self.callbackBlock) {
        self.callbackBlock(RDActionSheetCallbackTypeWillPresentActionSheet, -1, nil);
    }
    else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(willPresentActionSheet:)]) {
            [self.delegate willPresentActionSheet:self];
        }
    }
    
    [UIView animateWithDuration:kActionSheetAnimationTime
                     animations:^{
                         CGFloat endPosition = startPosition - self.frame.size.height;
                         self.frame = CGRectMake(self.frame.origin.x, endPosition, self.frame.size.width, self.frame.size.height);
                         self.blackOutView.alpha = kBlackoutViewFadeInOpacity;
                     }
                     completion:^(BOOL finished) {
                         if (self.callbackBlock) {
                             self.callbackBlock(RDActionSheetCallbackTypeDidPresentActionSheet, -1, nil);
                         }
                         else {
                             if (self.delegate && [self.delegate respondsToSelector:@selector(didPresentActionSheet:)]) {
                                 [self.delegate didPresentActionSheet:self];
                             }
                         }
                     }];
}

#pragma mark - Helpers

- (CGFloat)calculateSheetHeight {
    return floorf((kButtonHeight * self.buttons.count) + (self.buttons.count * kButtonPadding) + kButtonHeight/2) + self.titleLabel.bounds.size.height + 4;
}

- (NSString *)title {
    return self.titleLabel.text;
}

@end

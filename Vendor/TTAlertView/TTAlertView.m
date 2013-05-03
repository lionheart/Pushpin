//
//  TTAlertView.m
//  TTAlertView
//
//  Created by Duncan Lewis on 10/12/12.
//  Copyright (c) 2012 Two Toasters. All rights reserved.
//

#import "TTAlertView.h"
#import "PPButton.h"
#import <QuartzCore/QuartzCore.h>
#import "PPCoreGraphics.h"

static CGFloat const kTTDefaultDialogLeftInset = 20.0f;
static CGFloat const kTTDefaultDialogRightInset = 20.0f;
static CGFloat const kTTDefaultDialogMinVerticalInset = 60.0f;

static CGFloat const kTTDefaultDialogContentTopInset = 14.0f;
static CGFloat const kTTDefaultDialogContentBottomInset = 4.0f;
static CGFloat const kTTDefaultDialogContentLeftInset = 10.0f;
static CGFloat const kTTDefaultDialogContentRightInset = 10.0f;

static CGFloat const kTTDefaultDialogContentTitleMessageSpacer = 8.0f; // space between the title label and the message label in the default layout

static CGFloat const kTTDefaultDialogButtonTopInset = 4.0f;
static CGFloat const kTTDefaultDialogButtonBottomInset = 8.0f;
static CGFloat const kTTDefaultDialogButtonLeftInset = 10.0f;
static CGFloat const kTTDefaultDialogButtonRightInset = 10.0f;

static CGFloat const kTTDefaultDialogButtonVerticalFirstSpacer = 10.0f; // the vertical distance between the first and second button in the #buttons > 2 vertical layout
static CGFloat const kTTDefaultDialogButtonVerticalSpacer = 4.0f; // the vertical distance between the buttons in the #buttons > 2 vertical layout
static CGFloat const kTTDefaultDialogButtonHorizontalSpacer = 8.0f; // the horizontal space between buttons
static CGFloat const kTTDefaultDialogButtonHeight = 44.0f;

@interface TTAlertView ()

@property (nonatomic, readonly) UIScrollView *messageScrollView; // used if the message excedes the maximum allowed size of the alert dialog

@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, strong) NSArray *otherButtonTitles;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) NSMutableDictionary *buttonSizeStrings;
@property (nonatomic, assign) BOOL usingCustomButtonSizes;

/**
 * Called when the alertview needs layout for a window
 */
- (void)layoutInWindow:(UIWindow *)window;

@end

@implementation TTAlertView

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [super init];
    if (self) {
        
        self.title = title;
        self.message = message;
        self.delegate = delegate;

        self.cancelButtonTitle = cancelButtonTitle;
        
        NSMutableArray *otherTitlesArray = [NSMutableArray array];
        id eachObject;
        va_list argList;
        if (otherButtonTitles) {
            _firstOtherButtonIndex = 1;
            [otherTitlesArray addObject:otherButtonTitles];
            va_start(argList, otherButtonTitles);
            while ( (eachObject = va_arg(argList, id)) ) {
                [otherTitlesArray addObject:eachObject];
            }
            va_end(argList);
        }
        self.otherButtonTitles = otherTitlesArray;
        
        self.usingCustomButtonSizes = NO;
        self.buttonSizeStrings = [NSMutableDictionary dictionary];
        _visible = NO;
        [self setUserInteractionEnabled:YES];
        
        [self setupDefaultInsets];
        [self setupView];
        
    }
    return self;
}

#pragma mark - Show/Dismiss

- (CAAnimationGroup *)popUpAnimation {
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    opacityAnimation.keyTimes = @[@0.0, @1.0];
    opacityAnimation.values = @[@0.0, @1.0];

    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

    CATransform3D scale1 = CATransform3DMakeScale(0.0, 0.0, 1);
    CATransform3D scale2 = CATransform3DMakeScale(1.15, 1.15, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.95, 0.95, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    scaleAnimation.values = @[
        [NSValue valueWithCATransform3D:scale1],
        [NSValue valueWithCATransform3D:scale2],
        [NSValue valueWithCATransform3D:scale3],
        [NSValue valueWithCATransform3D:scale4]
    ];
    scaleAnimation.keyTimes = @[@0.0, @0.70, @0.85, @1.0];
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    scaleAnimation.duration = .4;
    
    animationGroup.animations = @[opacityAnimation, scaleAnimation];
    return animationGroup;
}

- (void)show
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    [self layoutInWindow:window];
    
    [self setAlpha:0.0f];
    [window addSubview:self];
    
    if([self.delegate respondsToSelector:@selector(willPresentAlertView:)]) {
        [self.delegate willPresentAlertView:self];
    }
    
    [UIView animateWithDuration:0.25f
                     animations:^{
                         [self setAlpha:1.0f];
                     }
                     completion:^(BOOL finished) {
                         _visible = YES;
                         if([self.delegate respondsToSelector:@selector(didPresentAlertView:)]) {
                             [self.delegate didPresentAlertView:self];
                         }
                     }];
    [self.containerView.layer addAnimation:[self popUpAnimation] forKey:@"popup"];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)index animated:(BOOL)animated
{
    if([self.delegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)]) {
        [self.delegate alertView:self willDismissWithButtonIndex:index];
    }
    
    [UIView animateWithDuration:0.25f
                     animations:^{
                         [self setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         _visible = NO;
                         if([self.delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)]) {
                             [self.delegate alertView:self didDismissWithButtonIndex:index];
                         }
                     }];
}

#pragma mark - Setters

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    if (self.titleLabel) {
        [self.titleLabel setText:title];
    }
    if(self.isVisible) {
        [self setNeedsLayout];   
    }
}

- (void)setMessage:(NSString *)message
{
    _message = [message copy];
    if (self.messageLabel) {
        [self.messageLabel setText:message];
    }
    if(self.isVisible) {
        [self setNeedsLayout];
    }
}

#pragma mark - Getters

- (NSInteger)numberOfButtons
{
    return [self.buttons count];
}

- (NSString *)buttonTitleAtIndex:(NSInteger)index {
    if (index == self.cancelButtonIndex) {
        return self.cancelButtonTitle;
    }
    else if (index >= self.firstOtherButtonIndex) {
        return [self.otherButtonTitles objectAtIndex:index - self.firstOtherButtonIndex];
    } else {
        return nil;
    }
}

#pragma mark - TTAlertView customization methods

- (void)setBackgroundImage:(UIImage *)image
{
    [self.backgroundView setImage:image];
}

- (void)setAlertContainerImage:(UIImage *)image
{
    [self.containerView setImage:image];
}

- (void)setButtonBackgroundImage:(UIImage *)image forState:(UIControlState)state atIndex:(NSUInteger)index
{
    [(PPButton *)[self.buttons objectAtIndex:index] setBackgroundImage:image forState:state];
    [(PPButton *)[self.buttons objectAtIndex:index] setBackgroundColor:[UIColor clearColor]];
    
    if ([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:index]]) {
        [self.buttonSizeStrings removeObjectForKey:[NSNumber numberWithInteger:index]];
        
        if ([self.buttonSizeStrings count] == 0) {
            self.usingCustomButtonSizes = NO;
        }
    }
}

- (void)setButtonBackgroundImage:(UIImage *)image forState:(UIControlState)state withSize:(CGSize)size atIndex:(NSUInteger)index
{
    self.usingCustomButtonSizes = YES;
    [self.buttonSizeStrings setObject:NSStringFromCGSize(size) forKey:[NSNumber numberWithInteger:index]];
    
    [(PPButton *)[self.buttons objectAtIndex:index] setBackgroundImage:image forState:state];
    [(PPButton *)[self.buttons objectAtIndex:index] setBackgroundColor:[UIColor clearColor]];
    
    if(self.isVisible) {
        [self setNeedsLayout];
    }
}

- (void)setButtonImage:(UIImage *)image forState:(UIControlState)state withSize:(CGSize)size atIndex:(NSUInteger)index
{
    self.usingCustomButtonSizes = YES;
    [self.buttonSizeStrings setObject:NSStringFromCGSize(size) forKey:[NSNumber numberWithInteger:index]];
    
    [(PPButton *)[self.buttons objectAtIndex:index] setImage:image forState:state];
    [(PPButton *)[self.buttons objectAtIndex:index] setBackgroundColor:[UIColor clearColor]];
    
    if(self.isVisible) {
        [self setNeedsLayout];
    }
}

#pragma mark - Buttons

- (void)addButtonWithTitle:(NSString *)title
{
    PPButton *otherButton = [[PPButton alloc] init];
    [otherButton addTarget:self action:@selector(otherButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [otherButton setTitle:title forState:UIControlStateNormal];
    [self.containerView addSubview:otherButton];
    [self.buttons insertObject:otherButton atIndex:([self.buttons count] - 1) + self.firstOtherButtonIndex];
    
    if(self.isVisible) {
        [self setNeedsLayout];
    }
}

- (void)setupButtons
{
    if (self.cancelButtonTitle != nil) {
        _cancelButtonIndex = 0;
    } else {
        _cancelButtonIndex = -1;
    }
    
    if ([self.otherButtonTitles count] > 0) {
        _firstOtherButtonIndex = _cancelButtonIndex + 1;
    } else {
        _firstOtherButtonIndex = -1;
    }
    
    self.buttons = [NSMutableArray array];
    
    PPButton *cancelButton = [[PPButton alloc] init];
    [cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:self.cancelButtonTitle forState:UIControlStateNormal];
    [self.containerView addSubview:cancelButton];
    [self.buttons insertObject:cancelButton atIndex:_cancelButtonIndex];
    
    [self.otherButtonTitles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self addButtonWithTitle:(NSString *)obj];
    }];
    
}

#pragma mark - Layout helpers

- (void)layoutSubviews
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    [self layoutInWindow:window];
}

- (void)setupDefaultInsets
{
    self.contentInsets = UIEdgeInsetsMake(kTTDefaultDialogContentTopInset, kTTDefaultDialogContentLeftInset, kTTDefaultDialogContentBottomInset, kTTDefaultDialogContentRightInset);
    self.buttonInsets = UIEdgeInsetsMake(kTTDefaultDialogButtonTopInset, kTTDefaultDialogButtonLeftInset, kTTDefaultDialogButtonBottomInset, kTTDefaultDialogButtonRightInset);
    
    self.containerLeftInset = kTTDefaultDialogLeftInset;
    self.containerRightInset = kTTDefaultDialogRightInset;
    self.containerMinVerticalInset = kTTDefaultDialogMinVerticalInset;
    
    self.contentTitleMessageSpacer = kTTDefaultDialogContentTitleMessageSpacer;
    self.buttonVerticalSpacerFirst = kTTDefaultDialogButtonVerticalFirstSpacer;
    self.buttonVerticalSpacer = kTTDefaultDialogButtonVerticalSpacer;
    self.buttonHorizontalSpacer = kTTDefaultDialogButtonHorizontalSpacer;
}

- (void)layoutInWindow:(UIWindow *)window
{
    [self setFrame:window.bounds];
    
    [self.backgroundView setFrame:self.bounds];
    
    // size title label
    CGFloat contentWidth = self.bounds.size.width - self.contentInsets.left - self.contentInsets.right - self.containerLeftInset - self.containerRightInset;
    CGSize titleTextSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font forWidth:contentWidth lineBreakMode:self.titleLabel.lineBreakMode];

    [self.titleLabel setFrame:(CGRect){ { self.contentInsets.left, self.contentInsets.top}, { contentWidth, titleTextSize.height } }];
    
    // buttons (layed out from bottom up)
    CGFloat totalButtonHeight = 0.0f; // space from the top of the topmost button to the bottom of the bottom most button. Does not include message-button spacer or contentBottomInset
    CGFloat totalButtonWidth = self.bounds.size.width - self.containerLeftInset - self.containerRightInset - self.buttonInsets.left - self.buttonInsets.right;
    
    if (self.usingCustomButtonSizes) {
        
        for(int i = 0; i < [self.buttons count]; i++) {
            
            if([self.buttons count] > 2) {
                // add up button heights
                CGFloat buttonHeight = kTTDefaultDialogButtonHeight;
                if ([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:i]]) {
                    CGSize buttonSize = CGSizeFromString([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:i]]);
                    buttonHeight = buttonSize.height;
                }
                totalButtonHeight += buttonHeight;
                totalButtonHeight += (i == 1) ? self.buttonVerticalSpacerFirst : 0;
                totalButtonHeight += (i >= 2) ? self.buttonVerticalSpacer : 0;
                
            } else {
                // largest button height is total button height
                CGFloat buttonHeight = kTTDefaultDialogButtonHeight;
                if ([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:i]]) {
                    CGSize buttonSize = CGSizeFromString([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:i]]);
                    buttonHeight = buttonSize.height;
                }
                totalButtonHeight = totalButtonHeight < buttonHeight ? buttonHeight : totalButtonHeight;
            }
            
        };
        
    } else {
        // default height if number of buttons <= 2, else use vertical layout height
        totalButtonHeight = [self.buttons count] > 2 ? (kTTDefaultDialogButtonHeight * [self.buttons count]) + self.buttonVerticalSpacerFirst + ([self.buttons count] - 2)*(self.buttonVerticalSpacer) : kTTDefaultDialogButtonHeight;
        
    }

    // max message size is (height of screen) - (min dialog vertical inset) - (content top inset) - (title height) - (content title-message spacer) - (content bottom inset) - (button top inset) - (button height) - (button bottom inset) - (min dialog vertical inset)
    CGFloat maxMessageHeight = self.bounds.size.height - self.containerMinVerticalInset - self.contentInsets.top - titleTextSize.height - self.contentTitleMessageSpacer - self.contentInsets.bottom - self.buttonInsets.top - totalButtonHeight - self.buttonInsets.bottom  - self.containerMinVerticalInset;
    CGSize messageTextSize = [self.messageLabel.text sizeWithFont:self.messageLabel.font constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:self.messageLabel.lineBreakMode];
    
    [self.messageLabel setFrame:(CGRect){ CGPointZero, { contentWidth, messageTextSize.height } }];
    [self.messageScrollView setFrame:(CGRect){ { self.contentInsets.left, self.contentInsets.top + self.titleLabel.frame.size.height + self.contentTitleMessageSpacer }, { contentWidth, MIN( maxMessageHeight, messageTextSize.height ) } }];
    [self.messageScrollView setContentSize:messageTextSize];
    
    // button layout
    __block CGFloat lastY = 0.0f;
    __block CGFloat lastX = 0.0f;
    
    // single button layout case (center horizontaly inside of totalButtonWidth)
    if ([self.buttons count] == 1) {
        
        PPButton *button = [self.buttons objectAtIndex:0];
        CGSize buttonSize = CGSizeMake(totalButtonWidth, totalButtonHeight);
        if ([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:0]]) {
            buttonSize = CGSizeFromString([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:0]]);
        }
        
        CGFloat x = self.buttonInsets.left + (totalButtonWidth/2 - buttonSize.width/2);
        CGFloat y = self.contentInsets.top + self.titleLabel.frame.size.height + self.contentTitleMessageSpacer + self.messageScrollView.frame.size.height + self.contentInsets.bottom + self.buttonInsets.top;
        [button setFrame:(CGRect){ { x, y }, buttonSize }];
        
    }
    // two buttons layout case
    else if ([self.buttons count] == 2) {
        
        // find remaining width after accounting for custom sized widths. Will be used if
        CGFloat standardButtonWidth = 0.0f;
        if(self.usingCustomButtonSizes) {
            CGFloat remainderWidth = totalButtonWidth - self.buttonHorizontalSpacer;
            for(NSString *sizeString in [self.buttonSizeStrings allValues]) {
                remainderWidth -= CGSizeFromString(sizeString).width;
            }
            standardButtonWidth = remainderWidth;
        } else {
            standardButtonWidth = (totalButtonWidth - self.buttonHorizontalSpacer) / 2.0f;
        }
        
        lastX = self.buttonInsets.left;
        [self.buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PPButton *button = (PPButton *)obj;
            
            CGSize buttonSize = CGSizeMake( standardButtonWidth, totalButtonHeight );
            if ([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:idx]]) {
                buttonSize = CGSizeFromString([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:idx]]);
            }
            
            CGFloat x = lastX + (idx == 1 ? self.buttonHorizontalSpacer : 0);
            CGFloat y = self.contentInsets.top + self.titleLabel.frame.size.height + self.contentTitleMessageSpacer + self.messageScrollView.frame.size.height + self.contentInsets.bottom + self.buttonInsets.top + (totalButtonHeight - buttonSize.height);
            [button setFrame:(CGRect){ { x, y }, buttonSize }];
            
            lastX = x + buttonSize.width;
            lastY = y;
            
        }];
    }
    // vertical (>2) button layout case. center horizontal, stack vertically
    else {
        
        lastY = self.contentInsets.top + self.titleLabel.frame.size.height + self.contentTitleMessageSpacer + self.messageScrollView.frame.size.height + self.contentInsets.bottom + self.buttonInsets.top + totalButtonHeight;
        [self.buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PPButton *button = (PPButton *)obj;
            
            CGSize buttonSize = CGSizeMake(totalButtonWidth, kTTDefaultDialogButtonHeight);
            if ([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:idx]]) {
                buttonSize = CGSizeFromString([self.buttonSizeStrings objectForKey:[NSNumber numberWithInteger:idx]]);
            }
            
            CGFloat x = self.buttonInsets.left + (totalButtonWidth/2 - buttonSize.width/2);
            CGFloat y = lastY - buttonSize.height - (idx == 1 ? self.buttonVerticalSpacerFirst : 0) - (idx > 1 ? self.buttonVerticalSpacer : 0);
            
            [button setFrame:(CGRect){ { x, y }, buttonSize }];
                
            lastY = y;
        }];
    }
    
    // finish sizing content view
    CGFloat dialogHeight = self.contentInsets.top + self.titleLabel.frame.size.height + self.contentTitleMessageSpacer + self.messageScrollView.frame.size.height + self.contentInsets.bottom + self.buttonInsets.top + totalButtonHeight + self.buttonInsets.bottom;
    CGRect containerFrame = (CGRect){ { self.containerLeftInset, MAX(self.containerMinVerticalInset, self.frame.size.height/2 - dialogHeight/2) }, { self.bounds.size.width - self.containerLeftInset - self.containerRightInset, dialogHeight } };
    [self.containerView setFrame:containerFrame];
    self.containerView.opaque = NO;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowRadius = 10.f;
    self.containerView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.containerView.layer.shadowOpacity = 0.5;

    UIGraphicsBeginImageContextWithOptions(containerFrame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect outerBorderRect = CGRectMake(0, 0, containerFrame.size.width, containerFrame.size.height);
    CGRect innerBorderRect = CGRectInset(outerBorderRect, 1, 1);
    CGRect rect = CGRectInset(innerBorderRect, 1, 1);
    
    CGContextSetLineWidth(context, 2.f);
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 0.2);
    CGContextAddRoundedRect(context, outerBorderRect, 8.f);
    CGContextStrokePath(context);

    CGContextSetLineWidth(context, 1.f);
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextAddRoundedRect(context, innerBorderRect, 6.f);
    CGContextStrokePath(context);

    CGContextAddRoundedRect(context, rect, 4.f);
    CGContextClip(context);
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();

    size_t num_locations = 3;
    CGFloat locations[3] = { 0.0, 0.5, 1.0 };
    CGFloat components[12] =	{
        0.212, 0.227, 0.275, 1.0,
        0.173, 0.184, 0.224, 1.0,
        0.114, 0.125, 0.161, 1.0
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
    CGPoint startPoint, endPoint;
    startPoint.x = 0.0;
    startPoint.y = 0.0;
    endPoint.x = 0.0;
    endPoint.y = containerFrame.size.height;
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    UIImage *finishedBackground = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *background = [[UIImageView alloc] initWithImage:finishedBackground];
    background.opaque = NO;
    background.backgroundColor = [UIColor clearColor];
    background.layer.backgroundColor = [UIColor clearColor].CGColor;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.containerView insertSubview:background atIndex:0];
}

- (void)setupView {
    CGRect frame = CGRectMake(0, 0, 320, 480);
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t numGradientComponents = 4;
    CGFloat gradientLocations[4] = { 0.0, 0.4, 0.6, 1.0 };
    CGFloat gradientComponents[16] = {
        0, 0, 0, 0.5,
        0, 0, 0, 0.3,
        0, 0, 0, 0.3,
        0, 0, 0, 0.5
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradientComponents, gradientLocations, numGradientComponents);
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(320, 0);
    CGContextSaveGState(context);
    CGContextAddRect(context, frame);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:backgroundView];
    _backgroundView = backgroundView;
    
    UIImageView *dialogContainerView = [[UIImageView alloc] init];
    [dialogContainerView setUserInteractionEnabled:YES];
    [self addSubview:dialogContainerView];
    _containerView = dialogContainerView;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = self.title;
    titleLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:18.f];

    [self.containerView addSubview:titleLabel];
    _titleLabel = titleLabel;
    
    UIScrollView *messageScrollView = [[UIScrollView alloc] init];
    [self.containerView addSubview:messageScrollView];
    _messageScrollView = messageScrollView;
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.text = self.message;
    messageLabel.numberOfLines = 0;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16.f];
    [self.messageScrollView addSubview:messageLabel];
    _messageLabel = messageLabel;
    
    [self setupButtons];
}

#pragma mark - Button action methods

- (void)cancelButtonAction:(id)sender
{
    if(self.buttonActionHandler) {
        self.buttonActionHandler(self.cancelButtonIndex);
    } else {
        if([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
            [self.delegate alertView:self clickedButtonAtIndex:self.cancelButtonIndex];
        }
    }
    [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:YES];
}

- (void)otherButtonAction:(id)sender
{
    NSInteger index = [self.buttons indexOfObject:sender];
    if(self.buttonActionHandler) {
        self.buttonActionHandler(index);
    } else {
        if([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
            [self.delegate alertView:self clickedButtonAtIndex:index];
        }
    }
    [self dismissWithClickedButtonIndex:index animated:YES];
}

@end

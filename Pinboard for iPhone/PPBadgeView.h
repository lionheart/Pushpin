//
//  PPBadgeView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import <UIKit/UIKit.h>

static const NSString *PPBadgeFontSize = @"fontSize";
static const NSString *PPBadgeNormalBackgroundColor = @"normalBackgroundColor";
static const NSString *PPBadgeActiveBackgroundColor = @"activeBackgroundColor";
static const NSString *PPBadgeDisabledBackgroundColor = @"disabledBackgroundColor";

@interface PPBadgeView : UIView

// Selectors
@property (nonatomic, readonly) SEL actionTouchUpInside;
@property (nonatomic, readonly, weak) id targetTouchUpInside;

@property (nonatomic, strong) UIView *badgeView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *disabledColor;

@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL selected;

- (id)initWithImage:(UIImage *)image;
- (id)initWithImage:(UIImage *)image options:(NSDictionary *)options;
- (id)initWithText:(NSString *)text;
- (id)initWithText:(NSString *)text options:(NSDictionary *)options;

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
- (void)updateBackgroundColor;

@end

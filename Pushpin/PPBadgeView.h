//
//  PPBadgeView.h
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

@import UIKit;

@class PPBadgeView;

@protocol PPBadgeDelegate <NSObject>

- (void)didSelectBadgeView:(PPBadgeView *)badgeView;
- (void)didTapAndHoldBadgeView:(PPBadgeView *)badgeView;

@end

@interface PPBadgeView : UIView

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, weak) id<PPBadgeDelegate> delegate;
@property (nonatomic, strong) UIView *badgeView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *disabledColor;

@property (nonatomic, strong) NSString *text;

@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL selected;

- (id)initWithImage:(UIImage *)image;
- (id)initWithImage:(UIImage *)image options:(NSDictionary *)options;
- (id)initWithText:(NSString *)text;
- (id)initWithText:(NSString *)text options:(NSDictionary *)options;

- (void)updateBackgroundColor;
- (void)gestureDetected:(UIGestureRecognizer *)recognizer;

@end

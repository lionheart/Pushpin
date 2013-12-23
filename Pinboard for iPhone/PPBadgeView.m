//
//  PPBadgeView.m
//  Pushpin
//
//  Created by Andy Muldowney on 11/21/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "PPBadgeView.h"
#import "PPTheme.h"

@implementation PPBadgeView

static const CGFloat PADDING_X = 4.0f;
static const CGFloat PADDING_Y = 2.0f;

@synthesize imageView = _imageView;
@synthesize textLabel = _textLabel;

- (id)initWithImage:(UIImage *)image {
    return [self initWithImage:image options:nil];
}

- (id)initWithImage:(UIImage *)image options:(NSDictionary *)options {
    self = [super init];
    if (self) {
        // Defaults
        NSMutableDictionary *badgeOptions = [@{
                                               PPBadgeFontSize: @(10.0f),
                                               PPBadgeNormalBackgroundColor: HEX(0x73c5ffff),
                                               PPBadgeActiveBackgroundColor: [self lightenColor:HEX(0x73c5ffff) amount:50],
                                               PPBadgeDisabledBackgroundColor: HEX(0xCCCCCCFF),
                                               } mutableCopy];
        [badgeOptions addEntriesFromDictionary:options];
        
        self.layer.cornerRadius = 1.0f;
        self.layer.backgroundColor = ((UIColor *)badgeOptions[PPBadgeNormalBackgroundColor]).CGColor;
        
        self.imageView = [[UIImageView alloc] initWithImage:image];
        [self addSubview:self.imageView];
        
        // Calculate our frame
        CGSize size = [@"badge" sizeWithAttributes:@{ NSFontAttributeName: [PPTheme tagFont] }];
        self.frame = CGRectMake(0, 0, size.height + (PADDING_X * 2), size.height + (PADDING_Y * 2));
        self.imageView.frame = CGRectMake(PADDING_X, PADDING_Y, size.height, size.height);
    }
    return self;
}

- (id)initWithText:(NSString *)text {
    return [self initWithText:text options:nil];
}

- (id)initWithText:(NSString *)text options:(NSDictionary *)options {
    self = [super init];
    if (self) {
        // Defaults
        NSMutableDictionary *badgeOptions = [@{
                                         PPBadgeFontSize: @(10.0f),
                                         PPBadgeNormalBackgroundColor: HEX(0x73c5ffff),
                                         PPBadgeActiveBackgroundColor: [self lightenColor:HEX(0x73c5ffff) amount:50],
                                         PPBadgeDisabledBackgroundColor: HEX(0xCCCCCCFF),
                                         } mutableCopy];
        [badgeOptions addEntriesFromDictionary:options];
        
        self.normalColor = badgeOptions[PPBadgeNormalBackgroundColor];
        self.selectedColor = badgeOptions[PPBadgeActiveBackgroundColor];
        self.disabledColor = badgeOptions[PPBadgeDisabledBackgroundColor];
        
        self.layer.cornerRadius = 1.0f;
        self.layer.backgroundColor = self.normalColor.CGColor;
        
        self.textLabel = [[UILabel alloc] init];
        self.textLabel.text = text;
        self.textLabel.font = [PPTheme tagFont];
        self.textLabel.textColor = [UIColor whiteColor];
        
        // Calculate our frame
        CGSize size = [text sizeWithAttributes:@{ NSFontAttributeName: self.textLabel.font }];
        self.frame = CGRectMake(0, 0, size.width + (PADDING_X * 2), size.height + (PADDING_Y * 2));
        self.textLabel.frame = CGRectMake(PADDING_X, PADDING_Y, size.width, size.height);
        [self addSubview:self.textLabel];
        
        self.enabled = YES;
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    if (controlEvents & UIControlEventTouchUpInside) {
        _targetTouchUpInside = target;
        _actionTouchUpInside = action;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.enabled) {
        self.selected = YES;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.superview];
    self.selected = CGRectContainsPoint(self.frame, touchPoint);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.superview];
    
    if (self.enabled && CGRectContainsPoint(self.frame, touchPoint)) {
        // Send touch up inside action
        if ([_targetTouchUpInside respondsToSelector:_actionTouchUpInside]) {
            [_targetTouchUpInside performSelector:_actionTouchUpInside withObject:self];
        }
    }
    
    if (self.enabled) {
        self.selected = NO;
    }
}

#pragma mark Setters
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (!self.imageView.image) {
        [super setBackgroundColor:[UIColor colorWithCGColor:self.layer.backgroundColor]];
    }
    else {
        [super setBackgroundColor:backgroundColor];
    }
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    [self updateBackgroundColor];
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    if (selected) {
        self.layer.backgroundColor = self.selectedColor.CGColor;
    }
    else {
        [self updateBackgroundColor];
    }
}

- (void)setNormalColor:(UIColor *)normalColor {
    _normalColor = normalColor;
    self.enabled = _enabled;
}

#pragma mark - Helpers

- (void)updateBackgroundColor {
    if (self.enabled) {
        self.layer.backgroundColor = self.normalColor.CGColor;
    }
    else {
        self.layer.backgroundColor = self.disabledColor.CGColor;
    }
}

- (UIColor *)lightenColor:(UIColor *)color amount:(CGFloat)amount {
    CGFloat h, s, b, a;
    if ([color getHue:&h saturation:&s brightness:&b alpha:&a]) {
        h = (b == 1) ? h * 0.98 : h;
        return [UIColor colorWithHue:h saturation:s brightness:(b + b * (amount / 100)) alpha:a];
    }
    
    return nil;
}

- (UIColor *)darkenColor:(UIColor *)color amount:(CGFloat)amount {
    return [self lightenColor:color amount:-(amount)];
}

@end

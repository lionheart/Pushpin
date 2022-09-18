#import <UIKit/UIKit.h>
#import <HSButton.h>

@interface HSBorderedButton : HSButton

@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable NSInteger borderPadding;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

@end

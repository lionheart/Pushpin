//
//  PPTableViewTitleView.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/2/14.
//
//

#import <UIKit/UIKit.h>

@interface PPTableViewTitleView : UIView

- (id)initWithText:(NSString *)text;
- (id)initWithText:(NSString *)text fontSize:(CGFloat)fontSize;

+ (CGFloat)heightWithText:(NSString *)text;
+ (CGFloat)heightWithText:(NSString *)text fontSize:(CGFloat)fontSize;

+ (PPTableViewTitleView *)headerWithText:(NSString *)text fontSize:(CGFloat)fontSize;
+ (PPTableViewTitleView *)headerWithText:(NSString *)text;

@end

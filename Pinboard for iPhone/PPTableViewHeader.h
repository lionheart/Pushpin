//
//  PPTableViewHeader.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/30/13.
//
//

#import <UIKit/UIKit.h>

@interface PPTableViewHeader : UIView

- (id)initWithText:(NSString *)text;
- (id)initWithText:(NSString *)text fontSize:(CGFloat)fontSize;

+ (CGFloat)heightWithText:(NSString *)text;
+ (CGFloat)heightWithText:(NSString *)text fontSize:(CGFloat)fontSize;

+ (PPTableViewHeader *)headerWithText:(NSString *)text fontSize:(CGFloat)fontSize;
+ (PPTableViewHeader *)headerWithText:(NSString *)text;

@end

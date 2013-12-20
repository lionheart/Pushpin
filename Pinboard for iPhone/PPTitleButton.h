//
//  PPTitleButton.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/20/13.
//
//

#import <UIKit/UIKit.h>

@interface PPTitleButton : UIButton

+ (instancetype)button;
- (void)setTitle:(NSString *)title imageName:(NSString *)imageName;

@end

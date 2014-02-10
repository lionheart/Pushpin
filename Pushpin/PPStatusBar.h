//
//  PPStatusBar.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/12/14.
//
//

@import UIKit;

@interface PPStatusBar : UIView

+ (instancetype)status;

- (void)showWithText:(NSString *)text;

@end

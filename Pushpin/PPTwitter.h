//
//  PPTwitter.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/17/14.
//
//

@import Foundation;

@interface PPTwitter : NSObject <UIActionSheetDelegate>

+ (instancetype)sharedInstance;

- (void)followScreenName:(NSString *)screenName
   withAccountScreenName:(NSString *)accountScreenName
                callback:(void (^)())callback;

- (void)followScreenName:(NSString *)screenName
                   point:(CGPoint)point
                    view:(UIView *)view
                callback:(void (^)())callback;

@end

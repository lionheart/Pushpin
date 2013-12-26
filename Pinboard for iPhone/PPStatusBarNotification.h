//
//  PPStatusBarNotification.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/25/13.
//
//

#import <Foundation/Foundation.h>

@interface PPStatusBarNotification : NSObject

+ (id)sharedNotification;
- (void)showWithText:(NSString *)text;

@end

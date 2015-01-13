//
//  PPShrinkBackTransition.h
//  Pushpin
//
//  Created by Dan Loewenherz on 8/1/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPShrinkBackTransition : NSObject <UIViewControllerTransitioningDelegate>

+ (PPShrinkBackTransition *)sharedInstance;

@end

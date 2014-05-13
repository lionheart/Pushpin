//
//  PPNavigationController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/25/13.
//
//

@import UIKit;
#import "PPAppDelegate.h"

@interface PPNavigationController : UINavigationController <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIBarButtonItem *splitViewControllerBarButtonItem;

@end

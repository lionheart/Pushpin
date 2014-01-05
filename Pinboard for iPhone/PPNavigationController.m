//
//  PPNavigationController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/25/13.
//
//

#import "PPNavigationController.h"
#import "PPNavigationBar.h"
#import "PPWebViewController.h"
#import "GenericPostViewController.h"

#import <FMDB/FMDatabase.h>

@implementation PPNavigationController

- (id)init {
    return [super initWithNavigationBarClass:[PPNavigationBar class] toolbarClass:nil];
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNavigationBarClass:[PPNavigationBar class] toolbarClass:nil];
    if (self) {
        self.viewControllers = @[rootViewController];
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
    return self;
}

- (void)viewDidLoad {
    __weak PPNavigationController *weakSelf = self;
    
    self.interactivePopGestureRecognizer.delegate = weakSelf;
    self.delegate = weakSelf;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.interactivePopGestureRecognizer.enabled = NO;

    [super pushViewController:viewController animated:animated];
}

#pragma mark - UINavigationControllerDelegate
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    return nil;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.interactivePopGestureRecognizer.enabled = YES;
    
    if ([[viewController class] isSubclassOfClass:[PPWebViewController class]]) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStyleDone target:nil action:nil];
    viewController.navigationItem.backBarButtonItem = backButton;
}

#pragma mark Status Bar Styles

// Overriding these methods ensure that child view controllers can set their own status bar styles

-(UIViewController *)childViewControllerForStatusBarStyle {
    return self.visibleViewController;
}

-(UIViewController *)childViewControllerForStatusBarHidden {
    return self.visibleViewController;
}

@end

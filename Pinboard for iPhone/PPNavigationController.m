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
    
    /*
    if ([[toVC class] isSubclassOfClass:[GenericPostViewController class]]) {
        GenericPostViewController *pvc = (GenericPostViewController *)toVC;
        if ([pvc.postDataSource respondsToSelector:@selector(barTintColor)]) {
            [self.navigationController.navigationBar setBarTintColor:[pvc.postDataSource barTintColor]];
        }
        
        if ([pvc.postDataSource respondsToSelector:@selector(title)]) {
            self.navigationItem.title = [pvc.postDataSource title];
        }
        
        if ([pvc.postDataSource respondsToSelector:@selector(titleViewWithDelegate:)]) {
            PPTitleButton *titleView = (PPTitleButton *)[pvc.postDataSource titleViewWithDelegate:pvc];
            self.navigationItem.titleView = titleView;
        }
    }
     */
    return nil;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.interactivePopGestureRecognizer.enabled = YES;
    
    if ([[viewController class] isSubclassOfClass:[PPWebViewController class]]) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
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

//
//  PPNavigationController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/25/13.
//
//

@import FMDB;
@import LHSCategoryCollection;

#import "PPNavigationController.h"
#import "PPNavigationBar.h"

#ifndef APP_EXTENSION_SAFE
#import "PPAboutViewController.h"
#import "PPChangelogViewController.h"
#endif

#import "PPAddBookmarkViewController.h"

@interface PPNavigationController ()

@property (nonatomic, strong) UIKeyCommand *createBookmarkKeyCommand;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

@end

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

    self.createBookmarkKeyCommand = [UIKeyCommand keyCommandWithInput:@"n"
                                                        modifierFlags:UIKeyModifierCommand
                                                               action:@selector(handleKeyCommand:)];
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

#pragma mark Status Bar Styles

// Overriding these methods ensure that child view controllers can set their own status bar styles

-(UIViewController *)childViewControllerForStatusBarStyle {
    return self.visibleViewController;
}

-(UIViewController *)childViewControllerForStatusBarHidden {
    return self.visibleViewController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientation {
#ifndef APP_EXTENSION_SAFE
    if ([[self.topViewController class] isSubclassOfClass:[PPAboutViewController class]]) {
        return UIInterfaceOrientationMaskPortrait;
    }

    if ([[self.topViewController class] isSubclassOfClass:[PPChangelogViewController class]]) {
        return UIInterfaceOrientationMaskPortrait;
    }
#endif

    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark - Key Commands

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[self.createBookmarkKeyCommand];
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.createBookmarkKeyCommand) {
        PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:@{} update:@(NO) callback:^(NSDictionary *response) {
        }];
        
        if ([UIApplication isIPad]) {
            addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        }

        [self presentViewController:(UIViewController *)addBookmarkViewController animated:YES completion:nil];
    }
}

@end

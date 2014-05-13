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
#import "PPGenericPostViewController.h"
#import "FeedListViewController.h"
#import "SettingsViewController.h"
#import "PPAboutViewController.h"
#import "PPChangelogViewController.h"
#import "AddBookmarkViewController.h"

#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

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

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.interactivePopGestureRecognizer.enabled = YES;
    
    if ([[viewController class] isSubclassOfClass:[PPWebViewController class]]) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {

    UIBarButtonItem *backButton = nil;
    
    if ([UIApplication isIPad]) {
        backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:nil action:nil];
        if ([[viewController class] isEqual:[PPGenericPostViewController class]] && navigationController.viewControllers.count == 1) {
            viewController.navigationItem.leftBarButtonItem = self.splitViewControllerBarButtonItem;
        }
    }
    else {
        if ([[viewController class] isEqual:[FeedListViewController class]]) {
            backButton = [[UIBarButtonItem alloc] initWithTitle:@"Browse" style:UIBarButtonItemStylePlain target:nil action:nil];
        }
        else {
            backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
        }
    }

    if (backButton) {
        viewController.navigationItem.backBarButtonItem = backButton;
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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[self.topViewController class] isSubclassOfClass:[PPAboutViewController class]]) {
        return UIInterfaceOrientationMaskPortrait;
    }

    if ([[self.topViewController class] isSubclassOfClass:[PPChangelogViewController class]]) {
        return UIInterfaceOrientationMaskPortrait;
    }

    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
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
        PPNavigationController *addBookmarkViewController = [AddBookmarkViewController addBookmarkViewControllerWithBookmark:@{} update:@(NO) callback:^(NSDictionary *response) {
        }];
        
        if ([UIApplication isIPad]) {
            addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        }

        [self presentViewController:(UIViewController *)addBookmarkViewController animated:YES completion:nil];
    }
}

@end

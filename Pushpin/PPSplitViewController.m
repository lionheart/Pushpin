//
//  PPSplitViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/8/14.
//
//

@import LHSCategoryCollection;

#import "PPSplitViewController.h"
#import "PPNavigationController.h"
#import "PPAddBookmarkViewController.h"
#import "PPAppDelegate.h"

@interface PPSplitViewController ()

@property (nonatomic, strong) UIKeyCommand *createBookmarkKeyCommand;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

@end

@implementation PPSplitViewController

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.viewControllers[1];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.viewControllers[1];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    static NSArray *keyCommands;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.createBookmarkKeyCommand = [UIKeyCommand keyCommandWithInput:@"c"
                                                            modifierFlags:UIKeyModifierAlternate
                                                                   action:@selector(handleKeyCommand:)];

        keyCommands = @[self.createBookmarkKeyCommand];
    });
    
    return keyCommands;
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.createBookmarkKeyCommand) {
        PPNavigationController *addBookmarkViewController = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:@{} update:@(NO) callback:^(NSDictionary *response) {
        }];
        
        if ([UIApplication isIPad]) {
            addBookmarkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        }

        [[PPAppDelegate sharedDelegate].navigationController presentViewController:addBookmarkViewController
                                                                        animated:YES
                                                                      completion:nil];
    }
}

@end

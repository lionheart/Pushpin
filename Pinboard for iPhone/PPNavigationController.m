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
#import "FMDatabase.h"

@implementation PPNavigationController

- (id)init {
    self = [super initWithNavigationBarClass:[UINavigationBar class] toolbarClass:nil];
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithNavigationBarClass:[UINavigationBar class] toolbarClass:nil];
    if (self) {
        self.viewControllers = @[rootViewController];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            #warning XXX Make generic
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            FMResultSet *results = [db executeQuery:@"SELECT url FROM bookmark WHERE unread=1 ORDER BY RANDOM() LIMIT 1"];
            [results next];
            NSString *urlString = [results stringForColumnIndex:0];
            [db close];

            dispatch_async(dispatch_get_main_queue(), ^{
                PPWebViewController *webViewController = [PPWebViewController webViewControllerWithURL:urlString];
                webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(closeModal:)];

                if (self.randomBookmarkNavigationController) {
                    [self.randomBookmarkNavigationController pushViewController:webViewController animated:YES];
                    [self becomeFirstResponder];
                }
                else {
                    self.randomBookmarkNavigationController = [[PPNavigationController alloc] initWithRootViewController:webViewController];
                    [self presentViewController:self.randomBookmarkNavigationController animated:YES completion:^{
                        [self becomeFirstResponder];
                    }];
                }
            });
        });
    }
}

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        self.randomBookmarkNavigationController = nil;
    }];
}

@end

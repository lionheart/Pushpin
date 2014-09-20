//
//  PPShareViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 9/19/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPShareViewController.h"
#import "PPAddBookmarkViewController.h"
#import "PPTheme.h"
#import "PPSettings.h"

#import <ASPinboard/ASPinboard.h>

@interface PPShareViewController ()

@end

@implementation PPShareViewController

- (instancetype)init {
    [PPTheme customizeUIElements];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.Pushpin"];
    [[ASPinboard sharedInstance] setToken:[sharedDefaults objectForKey:@"token"]];

    PPAddBookmarkViewController *addBookmarkViewController = [[PPAddBookmarkViewController alloc] init];
    addBookmarkViewController.presentedFromShareSheet = YES;
    return [[PPShareViewController alloc] initWithRootViewController:addBookmarkViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
    [UIView animateWithDuration:.4 animations:^{
         self.view.transform = CGAffineTransformIdentity;
    }];
}

@end

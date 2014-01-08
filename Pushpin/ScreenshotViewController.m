//
//  ScreenshotViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/25/13.
//
//

#import "ScreenshotViewController.h"
#import "PPTheme.h"
#import "PPStatusBarNotification.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSCategoryCollection/UIScreen+LHSAdditions.h>

@interface ScreenshotViewController ()

@property (nonatomic, strong) UIWindow *notification;
@property (nonatomic, strong) UIView *notificationContainer;

@end

@implementation ScreenshotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"blah";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[PPStatusBarNotification sharedNotification] showWithText:@"Your bookmarks have synced."];
}

@end

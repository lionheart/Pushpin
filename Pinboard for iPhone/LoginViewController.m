//
//  LoginViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "NSData+Additions.h"
#import <ASPinboard/ASPinboard.h>
#import "PrimaryNavigationViewController.h"
#import "PinboardDataSource.h"
#import "FeedListViewController.h"
#import "RPSTPasswordManagementAppService.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize activityIndicator;
@synthesize textView;
@synthesize progressView;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize activityIndicatorFrameBottom;
@synthesize activityIndicatorFrameTop;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    gradient.frame = CGRectMake(0, 0, 320, screenBounds.size.height);
    gradient.colors = [NSArray arrayWithObjects:(id)[HEX(0x06C6FFFF) CGColor], (id)[HEX(0x2E63FFFF) CGColor], nil];
    [self.view.layer addSublayer:gradient];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin"]];
    imageView.frame = CGRectMake(60, 10, 218, 213);
    [self.view addSubview:imageView];

    self.usernameTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 250, 300, 40)];
    self.usernameTextField.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:18];
    self.usernameTextField.textAlignment = NSTextAlignmentCenter;
    self.usernameTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.usernameTextField.backgroundColor = [UIColor whiteColor];
    self.usernameTextField.delegate = self;
    self.usernameTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    self.usernameTextField.rightViewMode = UITextFieldViewModeWhileEditing;
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameTextField.placeholder = NSLocalizedString(@"Username", nil);
    self.usernameTextField.layer.cornerRadius = 3;
    self.usernameTextField.layer.borderWidth = 1;
    self.usernameTextField.layer.borderColor = HEX(0x4A5768FF).CGColor;
    [self.view addSubview:self.usernameTextField];

    self.passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 300, 300, 40)];
    self.passwordTextField.font = [UIFont fontWithName:[AppDelegate mediumFontName] size:18];
    self.passwordTextField.textAlignment = NSTextAlignmentCenter;
    self.passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordTextField.backgroundColor = [UIColor whiteColor];
    self.passwordTextField.delegate = self;
    self.passwordTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.passwordTextField.returnKeyType = UIReturnKeyDone;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.passwordTextField.placeholder = NSLocalizedString(@"Password", nil);
    self.passwordTextField.layer.cornerRadius = 3;
    self.passwordTextField.layer.borderWidth = 1;
    self.passwordTextField.layer.borderColor = HEX(0x4A5768FF).CGColor;
    [self.view addSubview:self.passwordTextField];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.frame = CGRectMake(20, 400, 280, 50);
    self.progressView.hidden = YES;
    [self.view addSubview:self.progressView];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 342, 320, 80)];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.textColor = [UIColor whiteColor];
    self.textView.editable = NO;
    self.textView.userInteractionEnabled = NO;
    self.textView.textAlignment = NSTextAlignmentCenter;
    self.textView.font = [UIFont fontWithName:[AppDelegate heavyFontName] size:14];
    self.textView.text = NSLocalizedString(@"Enter your Pinboard credentials above. Email support support@aurora.io if you have any issues.", nil);
    [self.view addSubview:self.textView];

    CGFloat radius = 5;
    CGRect buttonRect = CGRectMake(0, 0, radius * 2, 30);
    CAGradientLayer *barButtonItemLayer = [CAGradientLayer layer];
    barButtonItemLayer.frame = buttonRect;
    barButtonItemLayer.cornerRadius = radius;
    barButtonItemLayer.masksToBounds = YES;
    barButtonItemLayer.borderWidth = 0.5;
    barButtonItemLayer.borderColor = HEX(0x4C586AFF).CGColor;
    barButtonItemLayer.colors = @[(id)HEX(0xFDFDFDFF).CGColor, (id)HEX(0xCED4E0FF).CGColor];
    barButtonItemLayer.startPoint = CGPointMake(0.5, 0);
    barButtonItemLayer.endPoint = CGPointMake(0.5, 1.0);

    UIGraphicsBeginImageContextWithOptions(buttonRect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [barButtonItemLayer renderInContext:context];
    UIImage *barButtonBackground = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:radius topCapHeight:15];
    UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(buttonRect.size, NO, 0);
    context = UIGraphicsGetCurrentContext();
    barButtonItemLayer.colors = @[(id)HEX(0xCED4E0FF).CGColor, (id)HEX(0xFDFDFDFF).CGColor];
    [barButtonItemLayer renderInContext:context];
    UIImage *barButtonBackgroundHighlighted = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:radius topCapHeight:15];
    UIGraphicsEndImageContext();

    self.onePasswordButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 352, 180, 44)];
    [self.onePasswordButton setTitle:@"Launch 1Password" forState:UIControlStateNormal];
    [self.onePasswordButton setImage:[UIImage imageNamed:@"1P-29"] forState:UIControlStateNormal];
    [self.onePasswordButton setImage:[UIImage imageNamed:@"1P-29"] forState:UIControlStateHighlighted];
    [self.onePasswordButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, radius)];
    [self.onePasswordButton setTitleEdgeInsets:UIEdgeInsetsMake(0, radius, 0, 0)];
    [self.onePasswordButton setBackgroundImage:barButtonBackground forState:UIControlStateNormal];
    [self.onePasswordButton setBackgroundImage:barButtonBackgroundHighlighted forState:UIControlStateHighlighted];
    [self.onePasswordButton addTarget:self action:@selector(sendToOnePassword) forControlEvents:UIControlEventTouchUpInside];

    self.onePasswordButton.titleLabel.font = [UIFont fontWithName:[AppDelegate heavyFontName] size:15];
    [self.onePasswordButton setTitleColor:HEX(0x4A5768FF) forState:UIControlStateNormal];
    [self.onePasswordButton setTitleShadowColor:HEX(0xFFFFFF00) forState:UIControlStateNormal];
    self.onePasswordButton.hidden = YES;
    [self.view addSubview:self.onePasswordButton];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    CGSize activitySize = self.activityIndicator.frame.size;
    self.activityIndicatorFrameTop = CGRectMake((320 - activitySize.width) / 2., 380, activitySize.width, activitySize.height);
    self.activityIndicatorFrameMiddle = CGRectMake((320 - activitySize.width) / 2., 400, activitySize.width, activitySize.height);
    self.activityIndicatorFrameBottom = CGRectMake((320 - activitySize.width) / 2., 425, activitySize.width, activitySize.height);
    self.activityIndicator.frame = self.activityIndicatorFrameTop;
    [self.view addSubview:self.activityIndicator];

    keyboard_shown = false;
    self.loginTimer = nil;
    
    [self resetLoginScreen];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressNotificationReceived:) name:kPinboardDataSourceProgressNotification object:nil];
}

- (void)progressNotificationReceived:(NSNotification *)notification {
    NSInteger current = [notification.userInfo[@"current"] integerValue];
    NSInteger total = [notification.userInfo[@"total"] integerValue];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (total == current) {
            [self.messageUpdateTimer invalidate];
            self.activityIndicator.frame = self.activityIndicatorFrameTop;
            self.progressView.hidden = YES;
            self.textView.text = @"Finalizing Metadata";
        }
        else {
            CGFloat f = current / (float)total;
            [self.progressView setProgress:f animated:YES];
        }
    });
}

- (void)keyboardWasShown:(NSNotification *)notification {
    if (!keyboard_shown) {
        NSDictionary *info = [notification userInfo];
        NSValue *notificationData = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
        
        NSTimeInterval duration = 0;
        NSValue *infoDuration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [infoDuration getValue:&duration];

        CGSize keyboardSize = [notificationData CGRectValue].size;

        CGRect frame = self.view.frame;
        frame.origin.y -= keyboardSize.height - 50;
        frame.size.height += keyboardSize.height - 50;

        [UIView animateWithDuration:duration animations:^(void) {
            self.view.frame = frame;
        }];
        
        keyboard_shown = true;
    }
}

- (void)keyboardWasHidden:(NSNotification *)notification {
    if (keyboard_shown) {
        NSDictionary *info = [notification userInfo];
        NSValue *notificationData = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
        CGSize keyboardSize = [notificationData CGRectValue].size;
        
        NSTimeInterval duration = 0;
        NSValue *infoDuration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [infoDuration getValue:&duration];

        CGRect frame = self.view.frame;
        frame.origin.y += keyboardSize.height - 50;
        frame.size.height -= keyboardSize.height - 50;

        [UIView animateWithDuration:duration animations:^(void) {
            self.view.frame = frame;
        }];

        keyboard_shown = false;
    }
}

- (void)bookmarkUpdateEvent:(NSNumber *)updated total:(NSNumber *)total {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:updated.floatValue / total.floatValue];
        
        if (updated.integerValue == total.integerValue) {
            UINavigationController *controller = [AppDelegate sharedDelegate].navigationController;
            controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:controller animated:YES completion:nil];
        }
    });
}

- (void)resetLoginScreen {
    [self.activityIndicator stopAnimating];
    self.textView.text = NSLocalizedString(@"Enter your Pinboard credentials above. Email support support@aurora.io if you have any issues.", nil);
    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor blackColor];
    self.passwordTextField.enabled = YES;
    self.passwordTextField.textColor = [UIColor blackColor];

    if ([RPSTPasswordManagementAppService passwordManagementAppIsAvailable]) {
        self.onePasswordButton.hidden = NO;
        self.textView.hidden = YES;
    }
}

- (void)updateLoadingMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *messages = @[
            @"Avoiding Acquisitions",
            @"Calibrating Snark Levels",
            @"Debugging Retain Cycles",
            @"Depixilating Monads",
            @"Force Quitting Development Tools",
            @"Generating Bookmark Indices",
            @"Parsing Unicode Date Formatters",
            @"Evaluating Sync Solutions",
            @"Binding ARC Evaluators",
            @"Garbage Collecting Stale Note Data",
            @"Applying Bookmark Upgrades",
            @"Initializing Null Pointers",
            @"Calibrating Tag Optimizations",
            @"Polishing Retina Displays",
            @"Refactoring Applicative Factors",
            @"Regenerating Provisioning Profiles",
            @"Releasing View Controllers",
            @"Reticulating Splines",
            @"Reversing Feed Originators",
        ];
        self.textView.text = [messages objectAtIndex:arc4random_uniform(messages.count)];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.progressView.frame = CGRectMake(20, 380, 280, 50);
            self.activityIndicator.frame = self.activityIndicatorFrameMiddle;
        });
    });
}

- (void)login {
    if (![usernameTextField.text isEqualToString:@""] && ![passwordTextField.text isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            
            self.activityIndicator.frame = self.activityIndicatorFrameTop;
            [self.activityIndicator startAnimating];
            self.usernameTextField.enabled = NO;
            self.usernameTextField.textColor = [UIColor grayColor];
            self.passwordTextField.enabled = NO;
            self.passwordTextField.textColor = [UIColor grayColor];
            self.onePasswordButton.hidden = YES;
            self.textView.hidden = NO;
            self.textView.text = NSLocalizedString(@"Verifying your credentials...", nil);
        
            ASPinboard *pinboard = [ASPinboard sharedInstance];
            [pinboard authenticateWithUsername:usernameTextField.text
                                      password:passwordTextField.text
                                       success:^(NSString *token) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               self.activityIndicator.frame = self.activityIndicatorFrameBottom;
                                               self.textView.text = NSLocalizedString(@"You have successfully authenticated. Please wait while we download your bookmarks.", nil);
                                               self.messageUpdateTimer = [NSTimer timerWithTimeInterval:6 target:self selector:@selector(updateLoadingMessage) userInfo:nil repeats:YES];
                                               [[NSRunLoop mainRunLoop] addTimer:self.messageUpdateTimer forMode:NSRunLoopCommonModes];
                                               
                                               self.progressView.hidden = NO;

                                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                   [delegate setToken:token];
                                                   PinboardDataSource *dataSource = [[PinboardDataSource alloc] init];
                                                   
                                                   [dataSource updateLocalDatabaseFromRemoteAPIWithSuccess:^{
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self.messageUpdateTimer invalidate];
                                                           delegate.navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                                                           [self presentViewController:delegate.navigationController
                                                                              animated:YES
                                                                            completion:nil];
                                                       });
                                                   }
                                                                                                   failure:nil
                                                                                                  progress:nil
                                                                                                   options:@{@"count": @(-1)}];
                                                   
                                                   [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                                                       [delegate setFeedToken:feedToken];
                                                   }];
                                                   
                                                   Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                   [mixpanel identify:[delegate username]];
                                                   [mixpanel.people set:@"$created" to:[NSDate date]];
                                                   [mixpanel.people set:@"$username" to:[delegate username]];
                                                   [mixpanel.people set:@"Browser" to:@"Webview"];
                                               });
                                           });
                                       }
                                       failure:^(NSError *error) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               switch (error.code) {
                                                   case PinboardErrorInvalidCredentials: {
                                                       WCAlertView *alert = [[WCAlertView alloc] initWithTitle:@"Authentication Error" message:NSLocalizedString(@"We couldn't log you in. Please make sure you've provided valid credentials.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                       [alert show];
                                                       [[Mixpanel sharedInstance] track:@"Failed to log in"];
                                                       [self resetLoginScreen];
                                                       break;
                                                   }
                                                       
                                                   case PinboardErrorTimeout: {
                                                       WCAlertView *alert = [[WCAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Pinboard is currently down. Please try logging in later.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                       [alert show];
                                                       [[Mixpanel sharedInstance] track:@"Cancelled log in"];
                                                       [self resetLoginScreen];
                                                       break;
                                                   }
                                                       
                                                   default:
                                                       break;
                                               }
                                           });
                                       }];
        });
    }
}

- (void)sendToOnePassword {
    [[UIApplication sharedApplication] openURL:[RPSTPasswordManagementAppService passwordManagementAppCompleteURLForSearchQuery:@"pinboard"]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else {
        [textField resignFirstResponder];
        if (![textField.text isEqualToString:@""]) {
            [self login];
        }
    }
    
    return YES;
}

@end

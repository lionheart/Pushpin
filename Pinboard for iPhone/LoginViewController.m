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
#import "TabBarViewController.h"
#import "NSData+Additions.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize activityIndicator;
@synthesize textView;
@synthesize progressView;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize loginConnection;
@synthesize loginRequestInProgress;
@synthesize loginTimer;
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
    self.usernameTextField.font = [UIFont fontWithName:@"Helvetica" size:18];
    self.usernameTextField.textAlignment = UITextAlignmentCenter;
    self.usernameTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.usernameTextField.borderStyle = UITextBorderStyleLine;
    self.usernameTextField.backgroundColor = [UIColor whiteColor];
    self.usernameTextField.delegate = self;
    self.usernameTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    self.usernameTextField.rightViewMode = UITextFieldViewModeWhileEditing;
    self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameTextField.placeholder = NSLocalizedString(@"Username", nil);
    [self.view addSubview:self.usernameTextField];

    self.passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 300, 300, 40)];
    self.passwordTextField.font = [UIFont fontWithName:@"Helvetica" size:18];
    self.passwordTextField.textAlignment = UITextAlignmentCenter;
    self.passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordTextField.borderStyle = UITextBorderStyleLine;
    self.passwordTextField.backgroundColor = [UIColor whiteColor];
    self.passwordTextField.delegate = self;
    self.passwordTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.passwordTextField.placeholder = NSLocalizedString(@"Password", nil);
    [self.view addSubview:self.passwordTextField];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.frame = CGRectMake(20, 400, 280, 50);
    self.progressView.hidden = YES;
    [self.view addSubview:self.progressView];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 340, 300, 80)];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.textColor = [UIColor whiteColor];
    self.textView.editable = NO;
    self.textView.userInteractionEnabled = NO;
    self.textView.textAlignment = UITextAlignmentCenter;
    self.textView.font = [UIFont fontWithName:@"Helvetica" size:14];
    self.textView.text = NSLocalizedString(@"Login Instructions", nil);
    [self.view addSubview:self.textView];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    CGSize activitySize = self.activityIndicator.frame.size;
    self.activityIndicatorFrameTop = CGRectMake((320 - activitySize.width) / 2., 380, activitySize.width, activitySize.height);
    self.activityIndicatorFrameBottom = CGRectMake((320 - activitySize.width) / 2., 425, activitySize.width, activitySize.height);
    self.activityIndicator.frame = self.activityIndicatorFrameTop;
    [self.view addSubview:self.activityIndicator];

    keyboard_shown = false;
    
    self.loginConnection = nil;
    self.loginRequestInProgress = NO;
    self.loginTimer = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasHidden:) name:UIKeyboardWillHideNotification object:nil];
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
        frame.origin.y -= keyboardSize.height - 100;
        frame.size.height += keyboardSize.height - 100;

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
        frame.origin.y += keyboardSize.height - 100;
        frame.size.height -= keyboardSize.height - 100;

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
            AppDelegate *delegate = [AppDelegate sharedDelegate];
            delegate.tabBarViewController = [[TabBarViewController alloc] init];
            delegate.tabBarViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:delegate.tabBarViewController animated:YES completion:nil];
        }
    });
}

- (void)cancelLogin {
    if (self.loginRequestInProgress) {
        [self.loginConnection cancel];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Pinboard is currently down. Please try logging in later.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        [[Mixpanel sharedInstance] track:@"Cancelled log in"];
        [self resetLoginScreen];
    }
}

- (void)loginFailed {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication Error" message:NSLocalizedString(@"Login Failed", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [[Mixpanel sharedInstance] track:@"Failed to log in"];

    [self resetLoginScreen];
}

- (void)resetLoginScreen {
    [self.activityIndicator stopAnimating];
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    self.loginRequestInProgress = NO;
    self.textView.text = NSLocalizedString(@"Login Instructions", nil);
    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor blackColor];
    self.passwordTextField.enabled = YES;
    self.passwordTextField.textColor = [UIColor blackColor];
}

- (void)login {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    if (![usernameTextField.text isEqualToString:@""] && ![passwordTextField.text isEqualToString:@""]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/user/api_token?format=json"]]];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", usernameTextField.text, passwordTextField.text];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        self.textView.text = NSLocalizedString(@"Login in Progress", nil);
        self.loginRequestInProgress = YES;
        self.loginTimer = [NSTimer timerWithTimeInterval:20.0 target:self selector:@selector(cancelLogin) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.loginTimer forMode:NSRunLoopCommonModes];

        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];

        self.activityIndicator.frame = self.activityIndicatorFrameTop;
        [self.activityIndicator startAnimating];
        self.usernameTextField.enabled = NO;
        self.usernameTextField.textColor = [UIColor grayColor];
        self.passwordTextField.enabled = NO;
        self.passwordTextField.textColor = [UIColor grayColor];

        self.loginConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        // [self.loginConnection start];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    self.activityIndicator.frame = self.activityIndicatorFrameBottom;

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    self.loginRequestInProgress = NO;
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if (payload == nil) {
        [self loginFailed];
    }
    else {
        [[AppDelegate sharedDelegate] setToken:[NSString stringWithFormat:@"%@:%@", usernameTextField.text, payload[@"result"]]];

        self.textView.text = NSLocalizedString(@"Login Successful", nil);
        self.progressView.hidden = NO;
        [[AppDelegate sharedDelegate] updateBookmarksWithDelegate:self];
        [[AppDelegate sharedDelegate] updateFeedToken:^{}];
        
        NSString *username = [[AppDelegate sharedDelegate] username];
        [mixpanel identify:username];
        [mixpanel.people identify:username];
        [mixpanel.people set:@"$created" to:[NSDate date]];
        [mixpanel.people set:@"$username" to:username];
        [mixpanel.people set:@"Browser" to:@"Webview"];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self loginFailed];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.text isEqualToString:@""]) {
        return NO;
    }
    
    [textField setUserInteractionEnabled:YES];

    if (textField == usernameTextField) {
        [passwordTextField becomeFirstResponder];
    }
    else {
        [textField resignFirstResponder];
    }
    
    [self login];
    return YES;
}

@end

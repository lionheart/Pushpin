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

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize activityIndicator;
@synthesize textView;
@synthesize progressView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, 320, 480);
    gradient.colors = [NSArray arrayWithObjects:(id)[HEX(0x06C6FFFF) CGColor], (id)[HEX(0x2E63FFFF) CGColor], nil];
    [self.view.layer addSublayer:gradient];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin"]];
    imageView.frame = CGRectMake(60, 10, 218, 213);
    [self.view addSubview:imageView];

    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 250, 300, 40)];
    textField.font = [UIFont fontWithName:@"Helvetica" size:18];
    textField.textAlignment = UITextAlignmentCenter;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.borderStyle = UITextBorderStyleLine;
    textField.backgroundColor = [UIColor whiteColor];
    textField.delegate = self;
    textField.keyboardType = UIKeyboardTypeAlphabet;
    textField.returnKeyType = UIReturnKeyDone;
    textField.rightViewMode = UITextFieldViewModeWhileEditing;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.placeholder = @"Pinboard API Token";
    [self.view addSubview:textField];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.frame = CGRectMake(20, 410, 280, 50);
    self.progressView.hidden = YES;
    [self.view addSubview:self.progressView];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 300, 300, 50)];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.textColor = [UIColor whiteColor];
    self.textView.textAlignment = UITextAlignmentCenter;
    self.textView.font = [UIFont fontWithName:@"Helvetica" size:14];
    self.textView.text = @"You can find your Pinboard API Token on the Pinboard password settings page.";
    [self.view addSubview:self.textView];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    CGSize activitySize = self.activityIndicator.frame.size;
    self.activityIndicator.frame = CGRectMake((320 - activitySize.width) / 2., 370, activitySize.width, activitySize.height);
    [self.view addSubview:self.activityIndicator];

    keyboard_shown = false;
    
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
        frame.origin.y -= keyboardSize.height - 150;
        frame.size.height += keyboardSize.height - 150;

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
        frame.origin.y += keyboardSize.height - 150;
        frame.size.height -= keyboardSize.height - 150;

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
            TabBarViewController *tabBarViewController = [[TabBarViewController alloc] init];
            tabBarViewController.modalPresentationStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:tabBarViewController animated:YES completion:nil];
        }
    });
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/user/api_token?format=json&auth_token=%@", textField.text]]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error.code == NSURLErrorUserCancelledAuthentication) {
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication Error" message:@"We couldn't log you in. Please make sure you've provided a valid token." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                   [alert show];
                               }
                               else {
                                   [[AppDelegate sharedDelegate] setToken:textField.text];

                                   [self.activityIndicator startAnimating];
                                   textField.enabled = NO;
                                   textField.textColor = [UIColor grayColor];

                                   self.textView.text = @"You have successfully authenticated. Please wait while we download your bookmarks.";
                                   self.progressView.hidden = NO;
                                   [[AppDelegate sharedDelegate] updateBookmarksWithDelegate:self];
                               }
                           }];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"%@", data);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.text isEqualToString:@""]) {
        return NO;
    }
    [textField setUserInteractionEnabled:YES];
    [textField resignFirstResponder];
    return YES;
}

@end

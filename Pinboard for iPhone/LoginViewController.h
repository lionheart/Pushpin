//
//  LoginViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface LoginViewController : UIViewController <UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate, BookmarkUpdateProgressDelegate> {
    BOOL keyboard_shown;
}

@property (nonatomic, retain) UITextField *usernameTextField;
@property (nonatomic, retain) UITextField *passwordTextField;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic) BOOL loginRequestInProgress;
@property (nonatomic) CGRect activityIndicatorFrameTop;
@property (nonatomic) CGRect activityIndicatorFrameBottom;
@property (nonatomic, retain) NSURLConnection *loginConnection;
@property (nonatomic, retain) NSTimer *loginTimer;

- (void)keyboardWasShown:(NSNotification *)notification;
- (void)keyboardWasHidden:(NSNotification *)notification;
- (void)login;
- (void)cancelLogin;
- (void)resetLoginScreen;
- (void)loginFailed;

@end

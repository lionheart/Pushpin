//
//  LoginViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UITableViewController <UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
    BOOL keyboard_shown;
}

@property (nonatomic, retain) UITextField *usernameTextField;
@property (nonatomic, retain) UITextField *passwordTextField;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic) CGRect activityIndicatorFrameTop;
@property (nonatomic) CGRect activityIndicatorFrameMiddle;
@property (nonatomic) CGRect activityIndicatorFrameBottom;
@property (nonatomic, retain) NSTimer *loginTimer;
@property (nonatomic, strong) NSTimer *messageUpdateTimer;
@property (nonatomic, strong) UIButton *onePasswordButton;

- (void)keyboardWasShown:(NSNotification *)notification;
- (void)keyboardWasHidden:(NSNotification *)notification;
- (IBAction)login:(id)sender;
- (void)resetLoginScreen;
- (void)updateLoadingMessage;
- (void)progressNotificationReceived:(NSNotification *)notification;
- (void)sendToOnePassword;

@end

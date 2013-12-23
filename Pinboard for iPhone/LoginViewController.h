//
//  LoginViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

#import <UIKit/UIKit.h>

typedef enum kLoginRows {
    kLoginUsernameRow,
    kLoginPasswordRow,
    kLogin1PasswordRow = 0
} kLoginRowType;

@interface LoginViewController : UITableViewController <UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
}

@property (nonatomic) BOOL keyboard_shown;
@property (nonatomic) CGRect activityIndicatorFrameBottom;
@property (nonatomic) CGRect activityIndicatorFrameMiddle;
@property (nonatomic) CGRect activityIndicatorFrameTop;
@property (nonatomic, strong) NSTimer *loginTimer;
@property (nonatomic, strong) NSTimer *messageUpdateTimer;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextView *textView;

- (void)login;
- (void)resetLoginScreen;
- (void)updateLoadingMessage;
- (void)progressNotificationReceived:(NSNotification *)notification;
- (void)showContactForm;

@end

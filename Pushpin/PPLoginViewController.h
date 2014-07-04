//
//  LoginViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

@import UIKit;

typedef NS_ENUM(NSInteger, PPLoginCredentialRowType) {
    PPLoginCredentialUsernameRow,
    PPLoginCredentialPasswordRow
};

typedef NS_ENUM(NSInteger, PPLoginSectionType) {
    PPLoginCredentialSection,
    PPLoginAuthTokenSection,
    PPLogin1PasswordSection
};

static NSInteger PPLoginSectionCount = PPLogin1PasswordSection + 1;

@interface PPLoginViewController : UITableViewController <UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate> {
}

@property (nonatomic) BOOL keyboard_shown;
@property (nonatomic) CGRect activityIndicatorFrameBottom;
@property (nonatomic) CGRect activityIndicatorFrameMiddle;
@property (nonatomic) CGRect activityIndicatorFrameTop;
@property (nonatomic, strong) NSTimer *loginTimer;
@property (nonatomic, strong) NSTimer *messageUpdateTimer;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSDictionary *textViewAttributes;

- (void)login;
- (void)resetLoginScreen;
- (void)updateLoadingMessage;
- (void)showContactForm;
- (BOOL)is1PasswordAvailable;

@end

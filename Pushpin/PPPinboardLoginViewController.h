//
//  PPPinboardLoginViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/18/12.
//
//

@import UIKit;
@import Beacon;

typedef NS_ENUM(NSInteger, PPLoginCredentialRowType) {
    PPLoginCredentialUsernameRow,
    PPLoginCredentialPasswordRow
};

typedef NS_ENUM(NSInteger, PPLoginSectionType) {
    PPLoginCredentialSection,
    PPLoginAuthTokenSection,
};

static NSInteger PPLoginSectionCount = PPLoginAuthTokenSection + 1;

@interface PPPinboardLoginViewController : UITableViewController <UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate, HSBeaconDelegate>

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

- (void)loginSuccessCallback:(BOOL)authTokenProvided;
- (void)loginFailureCallback:(NSError *)error authTokenProvided:(BOOL)authTokenProvided;
- (void)syncCompletedCallback;
- (void)updateProgressCallback:(NSInteger)current total:(NSInteger)total;

@end

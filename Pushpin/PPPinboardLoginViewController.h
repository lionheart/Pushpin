//
//  PPPinboardLoginViewController.h
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

#ifdef PINBOARD
typedef NS_ENUM(NSInteger, PPLoginSectionType) {
    PPLoginCredentialSection,
    PPLoginAuthTokenSection,
    PPLogin1PasswordSection
};
#endif

#ifdef DELICIOUS
typedef NS_ENUM(NSInteger, PPLoginSectionType) {
    PPLoginCredentialSection,
    PPLogin1PasswordSection,
    
    // Unused
    PPLoginAuthTokenSection,
};
#endif

static NSInteger PPLoginSectionCount = PPLogin1PasswordSection + 1;

@interface PPPinboardLoginViewController : UITableViewController <UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>

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

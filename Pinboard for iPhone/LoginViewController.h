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

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UIProgressView *progressView;

- (void)keyboardWasShown:(NSNotification *)notification;
- (void)keyboardWasHidden:(NSNotification *)notification;

@end

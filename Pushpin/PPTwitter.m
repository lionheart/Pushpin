//
//  PPTwitter.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/17/14.
//
//

#import "PPTwitter.h"
#import "AppDelegate.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface PPTwitter ()

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation PPTwitter

+ (instancetype)sharedInstance {
    static PPTwitter *twitter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        twitter = [[PPTwitter alloc] init];
    });
    return twitter;
}

- (id)init {
    self = [super init];
    if (self) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return self;
}

- (void)followScreenName:(NSString *)screenName withAccountScreenName:(NSString *)accountScreenName callback:(void (^)())callback {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitter = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSString *identifier;
    for (ACAccount *account in [accountStore accountsWithAccountType:twitter]) {
        if ([account.username isEqualToString:accountScreenName]) {
            identifier = account.identifier;
            break;
        }
    }
    
    if (identifier) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ACAccount *account = [accountStore accountWithIdentifier:identifier];
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"]
                                                       parameters:@{@"screen_name": screenName, @"follow": @"true"}];
            [request setAccount:account];
            
            [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                
                NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (response[@"errors"]) {
                        NSString *code = [NSString stringWithFormat:@"Twitter Error #%@", response[@"errors"][0][@"code"]];
                        NSString *message = [NSString stringWithFormat:@"%@", response[@"errors"][0][@"message"]];
                        [[[UIAlertView alloc] initWithTitle:code
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil] show];
                    }
                    else {
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                    message:[NSString stringWithFormat:@"You are now following @%@!", screenName]
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil] show];
                    }
                });
                
                if (callback) {
                    callback();
                }

                self.actionSheet = nil;
            }];
        });
    }
}

- (void)followScreenName:(NSString *)screenName
                   point:(CGPoint)point
                    view:(UIView *)view
                callback:(void (^)())callback {

    self.username = screenName;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *twitter = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        void (^AccessGrantedBlock)(UIAlertView *) = ^(UIAlertView *loadingAlertView) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Twitter Account:", nil)
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:nil];

                NSMutableDictionary *accounts = [NSMutableDictionary dictionary];
                NSString *accountScreenName;
                for (ACAccount *account in [accountStore accountsWithAccountType:twitter]) {
                    accountScreenName = account.username;
                    [self.actionSheet addButtonWithTitle:accountScreenName];
                    [accounts setObject:account.identifier forKey:accountScreenName];
                }
                
                if (loadingAlertView) {
                    [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                }
                
                // Properly set the cancel button index
                [self.actionSheet addButtonWithTitle:@"Cancel"];
                self.actionSheet.cancelButtonIndex = self.actionSheet.numberOfButtons - 1;
                
                if ([accounts count] > 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.actionSheet showFromRect:(CGRect){point, {1, 1}}
                                                inView:view
                                              animated:YES];
                    });
                }
                else if ([accounts count] == 1) {
                    [self followScreenName:screenName withAccountScreenName:accountScreenName callback:callback];
                }
            });
        };
        
        if (twitter.accessGranted) {
            AccessGrantedBlock(nil);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *loadingAlertView = [[UIAlertView alloc] initWithTitle:@"Loading"
                                                                           message:@"Requesting access to your Twitter accounts."
                                                                          delegate:nil
                                                                 cancelButtonTitle:nil
                                                                 otherButtonTitles:nil];
                [loadingAlertView show];
                
                self.activityIndicator.center = CGPointMake(CGRectGetWidth(loadingAlertView.bounds)/2, CGRectGetHeight(loadingAlertView.bounds)-45);
                [self.activityIndicator startAnimating];
                [loadingAlertView addSubview:self.activityIndicator];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [accountStore requestAccessToAccountsWithType:twitter
                                                          options:nil
                                                       completion:^(BOOL granted, NSError *error) {
                                                           if (granted) {
                                                               AccessGrantedBlock(loadingAlertView);
                                                           }
                                                           else {
                                                               [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                                               [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error.", nil) message:@"There was an error connecting to Twitter." delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                                           }
                                                       }];
                });
            });
        }
    });
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    self.actionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.actionSheet && buttonIndex >= 0) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

        if ([[actionSheet title] isEqualToString:NSLocalizedString(@"Select Twitter Account:", nil)]) {
            [[PPTwitter sharedInstance] followScreenName:self.username withAccountScreenName:buttonTitle callback:^{
                self.actionSheet = nil;
            }];
        }
    }
    self.actionSheet = nil;
}

@end

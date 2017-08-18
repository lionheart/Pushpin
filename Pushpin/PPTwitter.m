//
//  PPTwitter.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/17/14.
//
//

@import LHSCategoryCollection;
@import Social;
@import Accounts;

#import "PPTwitter.h"
#import "PPAppDelegate.h"

@interface PPTwitter ()

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) UIAlertController *actionSheet;

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
                    UIAlertController *alert;
                    if (response[@"errors"]) {
                        NSString *code = [NSString stringWithFormat:@"Twitter Error #%@", response[@"errors"][0][@"code"]];
                        NSString *message = [NSString stringWithFormat:@"%@", response[@"errors"][0][@"message"]];
                        
                        alert = [UIAlertController lhs_alertViewWithTitle:code message:message];
                    } else {
                        alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Success", nil)
                                                                  message:[NSString stringWithFormat:@"You are now following @%@!", screenName]];
                    }

                    [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
                    [[UIViewController lhs_topViewController] presentViewController:alert animated:YES completion:nil];
                });
                
                if (callback) {
                    callback();
                }
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
        
        void (^AccessGrantedBlock)(UIAlertController *) = ^(UIAlertController *loadingAlertView) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionSheet = [UIAlertController lhs_actionSheetWithTitle:NSLocalizedString(@"Select Twitter Account:", nil)];

                NSMutableDictionary *accounts = [NSMutableDictionary dictionary];
                NSString *accountScreenName;
                for (ACAccount *account in [accountStore accountsWithAccountType:twitter]) {
                    accountScreenName = account.username;
                    [self.actionSheet lhs_addActionWithTitle:accountScreenName
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [[PPTwitter sharedInstance] followScreenName:self.username withAccountScreenName:action.title callback:nil];
                                                     }];

                    [accounts setObject:account.identifier forKey:accountScreenName];
                }
                
#warning Is this the right way to check if an alert controller is visible?
                if (loadingAlertView.isFirstResponder) {
                    [loadingAlertView.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }
                
                [self.actionSheet lhs_addActionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil];
                
                if ([accounts count] > 1) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.actionSheet.popoverPresentationController.sourceView = view;
                        self.actionSheet.popoverPresentationController.sourceRect = (CGRect){point, {1, 1}};
                        [[UIViewController lhs_topViewController] presentViewController:self.actionSheet animated:YES completion:nil];
                    });
                } else if ([accounts count] == 1) {
                    [self followScreenName:screenName withAccountScreenName:accountScreenName callback:callback];
                }
            });
        };
        
        if (twitter.accessGranted) {
            AccessGrantedBlock(nil);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *loadingAlertView = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Loading", nil)
                                                                                        message:NSLocalizedString(@"Requesting access to your Twitter accounts.", nil)];
                [[UIViewController lhs_topViewController] presentViewController:loadingAlertView animated:YES completion:nil];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [accountStore requestAccessToAccountsWithType:twitter
                                                          options:nil
                                                       completion:^(BOOL granted, NSError *error) {
                                                           if (granted) {
                                                               AccessGrantedBlock(loadingAlertView);
                                                           } else {
                                                               [loadingAlertView.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                                               
                                                               UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"Error.", nil)
                                                                                                                            message:NSLocalizedString(@"There was an error connecting to Twitter.", nil)];
                                                               [alert lhs_addActionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
                                                               [[UIViewController lhs_topViewController] presentViewController:alert animated:YES completion:nil];
                                                           }
                                                       }];
                });
            });
        }
    });
}

@end

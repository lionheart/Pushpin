//
//  PPMailChimp.m
//  Pushpin
//
//  Created by Eric Olszewski on 6/25/15.
//  Copyright (c) 2015 Lionheart Software. All rights reserved.
//

@import ChimpKit;
@import LHSCategoryCollection;

#import "PPMailChimp.h"

@interface PPMailChimp ()

@end

@implementation PPMailChimp

+ (UIAlertController *)mailChimpSubscriptionAlertController {
    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:@"Subscribe"
                                                                 message:@"Enter your email address to receive occassional announcements and news about Pushpin Cloud."];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Email Address";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    
    [alert lhs_addActionWithTitle:@"Cancel"
                            style:UIAlertActionStyleCancel
                          handler:^(UIAlertAction *action) {
                              
                          }];
    
    [alert lhs_addActionWithTitle:@"Subscribe"
                            style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction *action) {
                              UITextField *textField = alert.textFields[0];
                              
                              NSMutableDictionary *params = [NSMutableDictionary dictionary];
                              params[@"id"] = @"eade7a8f4c";
                              params[@"email"] = @{@"email": textField.text};
                              params[@"double_optin"] = @"false";
                              params[@"update_existing"] = @"true";
                              
                              [[ChimpKit sharedKit] callApiMethod:@"lists/subscribe"
                                                       withParams:params
                                             andCompletionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                                 NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                 DLog(@"Response String: %@", responseString);
                                                 
                                                 id parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                 
                                                 if (![parsedResponse isKindOfClass:[NSDictionary class]] || ![parsedResponse[@"email"] isKindOfClass:[NSString class]] || error) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         UIAlertController *errorAlert = [UIAlertController lhs_alertViewWithTitle:@"Subscription Failed" message:@"We couldn't subscribe you to the list.  Please check your email address and try again."];
                                                         
                                                         [errorAlert lhs_addActionWithTitle:@"OK"
                                                                                      style:UIAlertActionStyleCancel
                                                                                    handler:^(UIAlertAction *action) {
                                                                                        
                                                                                    }];
                                                         [[UIViewController lhs_topViewController] presentViewController:errorAlert animated:YES completion:nil];
                                                     });
                                                 } else {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         UIAlertController *successAlert = [UIAlertController lhs_alertViewWithTitle:@"Subscription Successful!" message:@"You will now receive email updates for Pushpin Cloud."];
                                                         
                                                         [successAlert lhs_addActionWithTitle:@"OK"
                                                                                        style:UIAlertActionStyleCancel
                                                                                      handler:^(UIAlertAction *action) {
                                                                                          
                                                                                      }];
                                                         [[UIViewController lhs_topViewController] presentViewController:successAlert animated:YES completion:nil];
                                                     });
                                                 }
                                             }];
                          }];
    
    return alert;
}

@end

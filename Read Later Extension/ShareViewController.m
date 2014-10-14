//
//  ShareViewController.m
//  Read Later Extension
//
//  Created by Dan Loewenherz on 9/21/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

@import MobileCoreServices;

#import "ShareViewController.h"
#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <ASPinboard/ASPinboard.h>

@interface ShareViewController ()

@end

@implementation ShareViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIViewController *activityViewController = [[UIViewController alloc] init];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    activityViewController.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];

    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    containerView.layer.cornerRadius = 10;
    containerView.backgroundColor = [UIColor whiteColor];
    [activityViewController.view addSubview:containerView];

    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activity startAnimating];
    activity.translatesAutoresizingMaskIntoConstraints = NO;
    [activityViewController.view addSubview:activity];
    
    [activityViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:activity
                                                                            attribute:NSLayoutAttributeBottom
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:containerView
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1
                                                                             constant:-30]];
    
    [activityViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:activity
                                                                            attribute:NSLayoutAttributeTop
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:containerView
                                                                            attribute:NSLayoutAttributeTop
                                                                           multiplier:1
                                                                             constant:30]];
    
    [activityViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:activity
                                                                            attribute:NSLayoutAttributeLeft
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:containerView
                                                                            attribute:NSLayoutAttributeLeft
                                                                           multiplier:1
                                                                             constant:30]];
    
    [activityViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:activity
                                                                            attribute:NSLayoutAttributeRight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:containerView
                                                                            attribute:NSLayoutAttributeRight
                                                                           multiplier:1
                                                                             constant:-30]];
    
    
    [activityViewController.view lhs_centerHorizontallyForView:containerView];
    [activityViewController.view lhs_centerVerticallyForView:containerView];

    [self presentViewController:activityViewController animated:YES completion:nil];
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
        NSString *token = [sharedDefaults objectForKey:@"token"];
        if (token.length > 0) {
            [[ASPinboard sharedInstance] setToken:token];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_group_t group = dispatch_group_create();
                __block NSString *urlString;
                __block NSString *title;
                
                NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
                for (NSItemProvider *itemProvider in item.attachments) {
                    if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeURL]) {
                        dispatch_group_enter(group);
                        [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeURL
                                                        options:0
                                              completionHandler:^(NSURL *url, NSError *error) {
                                                  urlString = url.absoluteString;
                                                  dispatch_group_leave(group);
                                              }];
                    }
                    
                    if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePlainText]) {
                        dispatch_group_enter(group);
                        [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePlainText
                                                        options:0
                                              completionHandler:^(NSString *text, NSError *error) {
                                                  title = text;
                                                  dispatch_group_leave(group);
                                              }];
                    }
                    
                    if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePropertyList]) {
                        dispatch_group_enter(group);
                        [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePropertyList
                                                        options:0
                                              completionHandler:^(NSDictionary *results, NSError *error) {
                                                  title = results[NSExtensionJavaScriptPreprocessingResultsKey][@"title"];
                                                  urlString = results[NSExtensionJavaScriptPreprocessingResultsKey][@"url"];
                                                  dispatch_group_leave(group);
                                              }];
                    }
                }
                
                void (^CompletionBlockInner)(NSString *title, NSString *message) = ^(NSString *title, NSString *message) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                                   message:message
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    [self presentViewController:alert animated:YES completion:^{
                        double delayInSeconds = 1;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [self dismissViewControllerAnimated:YES completion:^{
                                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                            }];
                        });
                    }];
                };
                
                void (^CompletionBlock)(NSString *title, NSString *message) = ^(NSString *title, NSString *message) {
                    if (activityViewController.presentingViewController) {
                        [activityViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                            CompletionBlockInner(title, message);
                        }];
                    }
                    else {
                        CompletionBlockInner(title, message);
                    }
                };
                
                NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
                BOOL readByDefault = [[sharedDefaults objectForKey:@"ReadByDefault"] boolValue];
                BOOL privateByDefault = [[sharedDefaults objectForKey:@"PrivateByDefault"] boolValue];
                
                void (^AddBookmarkBlock)(NSString *urlString, NSString *title) = ^(NSString *urlString, NSString *title) {
                    [[ASPinboard sharedInstance] addBookmarkWithURL:urlString
                                                              title:title
                                                        description:@""
                                                               tags:@""
                                                             shared:!privateByDefault
                                                             unread:!readByDefault
                                                            success:^{
                                                                CompletionBlock(NSLocalizedString(@"Success!", nil), NSLocalizedString(@"Your bookmark was added.", nil));
                                                            }
                                                            failure:^(NSError *error) {
                                                                CompletionBlock(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@. %@", NSLocalizedString(@"There was an error saving this bookmark.", nil), error.localizedDescription]);
                                                            }];
                };
                
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    if (urlString) {
                        if (title.length > 0) {
                            AddBookmarkBlock(urlString, title);
                        }
                        else {
                            [PPUtilities retrievePageTitle:[NSURL URLWithString:urlString]
                                                  callback:^(NSString *title, NSString *description) {
                                                      if (title.length > 0) {
                                                          AddBookmarkBlock(urlString, title);
                                                      }
                                                      else {
                                                          [self dismissViewControllerAnimated:YES completion:^{
                                                              UIAlertController *controller = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"No Title Found", nil)
                                                                                                                                message:NSLocalizedString(@"Pushpin couldn't retrieve a title for this bookmark. Would you like to add this bookmark with the URL as the title?", nil)];
                                                              
                                                              [controller lhs_addActionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                  AddBookmarkBlock(urlString, urlString);
                                                              }];
                                                              
                                                              [controller lhs_addActionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                  [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                                                              }];
                                                              
                                                              [self presentViewController:controller animated:YES completion:nil];
                                                          }];
                                                      }
                                                  }];
                        }
                    }
                    else {
                        CompletionBlock(NSLocalizedString(@"Uh oh.", nil), NSLocalizedString(@"You can't add a bookmark without a URL.", nil));
                    }
                });
            });
        }
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid Token", nil)
                                                                           message:NSLocalizedString(@"Please open Pushpin to refresh your credentials.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}

@end

//
//  ShareViewController.m
//  Read Later Extension
//
//  Created by Daniel Loewenherz on 8/17/17.
//  Copyright © 2017 Lionheart Software. All rights reserved.
//

@import MobileCoreServices;
@import LHSCategoryCollection;
@import TMReachability;
@import ASPinboard;

#import "ShareViewController.h"
#import "PPUtilities.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (CGSize)preferredContentSize {
    return CGSizeMake(100, 100);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    UIAlertController *loadingAlert = [UIAlertController lhs_alertViewWithTitle:@"Bookmarking..." message:@""];
    [loadingAlert lhs_addActionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
    [self presentViewController:loadingAlert animated:YES completion:^{
        TMReachability *reach = [TMReachability reachabilityForInternetConnection];
        if (reach.isReachable) {
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
                        UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:title
                                                                                        message:message
                                                                                 preferredStyle:UIAlertControllerStyleAlert];

                        [self dismissViewControllerIfPresented:loadingAlert newController:alert2 withCompletion:^{
                            double delayInSeconds = 1;
                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                [self dismissViewControllerAnimated:YES completion:^{
                                    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                                }];
                            });
                        }];
                    };

                    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
                    BOOL readByDefault = [[sharedDefaults objectForKey:@"ReadByDefault"] boolValue];
                    BOOL privateByDefault = [[sharedDefaults objectForKey:@"PrivateByDefault"] boolValue];

                    void (^AddBookmarkBlock)(NSString *urlString, NSString *title) = ^(NSString *urlString, NSString *title) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [[ASPinboard sharedInstance] addBookmarkWithURL:urlString
                                                                      title:title
                                                                description:@""
                                                                       tags:@""
                                                                     shared:!privateByDefault
                                                                     unread:!readByDefault
                                                                    success:^{
                                                                        CompletionBlockInner(NSLocalizedString(@"Success!", nil), NSLocalizedString(@"Your bookmark was added.", nil));
                                                                    }
                                                                    failure:^(NSError *error) {
                                                                        CompletionBlockInner(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@. %@", NSLocalizedString(@"There was an error saving this bookmark.", nil), error.localizedDescription]);
                                                                    }];
                        });
                    };

                    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                        if (urlString) {
                            if (title.length > 0) {
                                AddBookmarkBlock(urlString, title);
                            } else {
                                [PPUtilities retrievePageTitle:[NSURL URLWithString:urlString]
                                                      callback:^(NSString *title, NSString *description) {
                                                          if (title.length > 0) {
                                                              AddBookmarkBlock(urlString, title);
                                                          } else {
                                                              UIAlertController *controller = [UIAlertController lhs_alertViewWithTitle:NSLocalizedString(@"No Title Found", nil)
                                                                                                                                message:NSLocalizedString(@"Pushpin couldn't retrieve a title for this bookmark. Would you like to add this bookmark with the URL as the title?", nil)];

                                                              [controller lhs_addActionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                  AddBookmarkBlock(urlString, urlString);
                                                              }];

                                                              [controller lhs_addActionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                  [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                                                              }];

                                                              [self dismissViewControllerIfPresented:loadingAlert newController:controller withCompletion:nil];
                                                          }
                                                      }];
                            }
                        } else {
                            CompletionBlockInner(NSLocalizedString(@"Uh oh.", nil), NSLocalizedString(@"You can't add a bookmark without a URL.", nil));
                        }
                    });
                });
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid Token", nil)
                                                                               message:NSLocalizedString(@"Please open Pushpin to refresh your credentials.", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                }];

                [self dismissViewControllerIfPresented:loadingAlert newController:alert withCompletion:nil];
            }
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:NSLocalizedString(@"No Internet connection is available.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }];

            [self dismissViewControllerIfPresented:loadingAlert newController:alert withCompletion:nil];
        }
    }];
}

- (void)dismissViewControllerIfPresented:(UIViewController *)controller newController:(UIViewController *)newController withCompletion:(void (^)(void))completion {
    if (controller.presentingViewController) {
        [controller dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:newController animated:YES completion:completion];
        }];
    } else {
        [self presentViewController:newController animated:YES completion:completion];
    }
}

@end

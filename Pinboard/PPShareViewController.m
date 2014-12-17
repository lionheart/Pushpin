//
//  PPShareViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 9/19/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

@import MobileCoreServices;

#import "PPShareViewController.h"
#import "PPNavigationController.h"
#import "PPAddBookmarkViewController.h"
#import "PPTheme.h"
#import "PPSettings.h"
#import "UIAlertController+LHSAdditions.h"

#import <ASPinboard/ASPinboard.h>

@interface PPShareViewController ()

@property (nonatomic) BOOL hasToken;

@end

@implementation PPShareViewController

- (instancetype)init {
    [PPTheme customizeUIElements];
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
        self.navigationBarHidden = YES;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    void (^InvalidCredentials)(UIViewController *controller) = ^(UIViewController *controller) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Token"
                                                                           message:@"Please open Pushpin to refresh your credentials."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }];
            [controller presentViewController:alert animated:YES completion:nil];
        });
    };

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    NSString *token = [sharedDefaults objectForKey:@"token"];
    self.hasToken = token.length > 0;
    
    if (self.hasToken) {
        [[ASPinboard sharedInstance] setToken:token];
    }

    PPAddBookmarkViewController *addBookmarkViewController = [[PPAddBookmarkViewController alloc] init];
    addBookmarkViewController.presentingViewControllersExtensionContext = self.extensionContext;

    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    for (NSItemProvider *itemProvider in item.attachments) {
        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeURL]) {
            [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeURL
                                            options:0
                                  completionHandler:^(NSURL *url, NSError *error) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          addBookmarkViewController.urlTextField.text = url.absoluteString;
                                          [addBookmarkViewController prefillTitleAndForceUpdate:YES];
                                      });
                                  }];
        }
        
        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePlainText]) {
            [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePlainText
                                            options:0
                                  completionHandler:^(NSString *text, NSError *error) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          NSURL *url = [NSURL URLWithString:text];
                                          if (url) {
                                              addBookmarkViewController.urlTextField.text = text;
                                              [addBookmarkViewController prefillTitleAndForceUpdate:YES];
                                          }
                                          else {
                                              addBookmarkViewController.titleTextField.text = text;
                                          }
                                      });
                                  }];
        }
        
        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePropertyList]) {
            [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePropertyList
                                            options:0
                                  completionHandler:^(NSDictionary *results, NSError *error) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          addBookmarkViewController.titleTextField.text = results[NSExtensionJavaScriptPreprocessingResultsKey][@"title"];
                                          addBookmarkViewController.urlTextField.text = results[NSExtensionJavaScriptPreprocessingResultsKey][@"url"];
                                          [addBookmarkViewController prefillTitleAndForceUpdate:YES];
                                      });
                                  }];
        }
    }
    
    BOOL readByDefault = [[sharedDefaults objectForKey:@"ReadByDefault"] boolValue];
    BOOL privateByDefault = [[sharedDefaults objectForKey:@"PrivateByDefault"] boolValue];
    addBookmarkViewController.tokenOverride = token;
    [addBookmarkViewController configureWithBookmark:@{@"private": @(privateByDefault),
                                                       @"unread": @(!readByDefault) }
                                              update:@(NO)
                                            callback:nil];

    PPNavigationController *navigation = [[PPNavigationController alloc] initWithRootViewController:addBookmarkViewController];
    navigation.modalPresentationStyle = UIModalPresentationFormSheet;
    navigation.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [PPTheme customizeUIElements];

    [self presentViewController:navigation animated:YES completion:^{
        if (self.hasToken) {
            [[ASPinboard sharedInstance] lastUpdateWithSuccess:^(NSDate *date) {
            } failure:^(NSError *error) {
                InvalidCredentials(navigation);
            }];
        }
        else {
            InvalidCredentials(navigation);
        }
    }];
}

@end

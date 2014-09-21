//
//  ShareViewController.m
//  Read Later Extension
//
//  Created by Dan Loewenherz on 9/21/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

@import MobileCoreServices;

#import "ShareViewController.h"
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
            
            void (^Block)(NSString *title, NSString *message) = ^(NSString *title, NSString *message) {
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
            
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                [[ASPinboard sharedInstance] addBookmarkWithURL:urlString
                                                          title:title
                                                    description:@""
                                                           tags:@""
                                                         shared:YES
                                                         unread:YES
                                                        success:^{
                                                            Block(NSLocalizedString(@"Success!", nil), NSLocalizedString(@"Your bookmark was added.", nil));
                                                        }
                                                        failure:^(NSError *error) {
                                                            Block(NSLocalizedString(@"Error", nil), [NSString stringWithFormat:@"%@. %@", NSLocalizedString(@"There was an error saving this bookmark.", nil), error.localizedDescription]);
                                                        }];
            });
        });
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Token"
                                                                       message:@"Please open Pushpin to refresh your credentials."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end

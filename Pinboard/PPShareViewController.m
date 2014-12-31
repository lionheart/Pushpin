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
#import "PPPinboardDataSource.h"

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
    
    void (^PresentController)(UINavigationController *nc) = ^(UINavigationController *nc) {
        PPAddBookmarkViewController *addBookmarkViewController = (PPAddBookmarkViewController *)nc.topViewController;
        addBookmarkViewController.presentingViewControllersExtensionContext = self.extensionContext;
        addBookmarkViewController.tokenOverride = token;

        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [PPTheme customizeUIElements];

        [self presentViewController:nc animated:YES completion:^{
            if (self.hasToken) {
                [[ASPinboard sharedInstance] lastUpdateWithSuccess:^(NSDate *date) {}
                                                           failure:^(NSError *error) {
                                                               InvalidCredentials(nc);
                                                           }];
            }
            else {
                InvalidCredentials(nc);
            }
        }];
    };

    void (^CompletionHandler)(NSString *urlString, NSString *title) = ^(NSString *urlString, NSString *title) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (urlString) {
                // Check if the bookmark is already in the database.
                __block NSDictionary *post;
                __block NSInteger count;
                
                NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP];
                [[FMDatabaseQueue databaseQueueWithPath:[containerURL URLByAppendingPathComponent:@"shared.db"].path] inDatabase:^(FMDatabase *db) {
                    FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) AS count, * FROM bookmark WHERE url=?" withArgumentsInArray:@[urlString]];
                    [results next];
                    count = [results intForColumnIndex:0];
                    
                    if (count > 0) {
                        post = [PPPinboardDataSource postFromResultSet:results];
                    }
                    
                    [results close];
                }];
                
                if (count == 0) {
                    UINavigationController *navigation = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:post
                                                                                                                     update:@(YES)
                                                                                                                   callback:nil];
                    PresentController(navigation);
                }
                else {
                    [[ASPinboard sharedInstance] bookmarkWithURL:urlString
                                                         success:^(NSDictionary *post) {
                                                             NSDictionary *bookmark = @{@"title": post[@"description"],
                                                                                        @"description": post[@"extended"],
                                                                                        @"url": urlString,
                                                                                        @"private": @([post[@"shared"] isEqualToString:@"no"]),
                                                                                        @"unread": @([post[@"toread"] isEqualToString:@"yes"]),
                                                                                        @"tags": post[@"tags"]};
                                                             UINavigationController *navigation = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:bookmark
                                                                                                                                                              update:@(YES)
                                                                                                                                                            callback:nil];
                                                             PresentController(navigation);
                                                         }
                                                         failure:^(NSError *error) {
                                                             BOOL readByDefault = [[sharedDefaults objectForKey:@"ReadByDefault"] boolValue];
                                                             BOOL privateByDefault = [[sharedDefaults objectForKey:@"PrivateByDefault"] boolValue];

                                                             PPNavigationController *navigation = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:@{@"title": title,
                                                                                                                                               @"url": urlString,
                                                                                                                                               @"private": @(privateByDefault),
                                                                                                                                               @"unread": @(!readByDefault) }
                                                                                                                                                              update:@(NO)
                                                                                                                                                            callback:nil];

                                                             PPAddBookmarkViewController *addBookmarkViewController = (PPAddBookmarkViewController *)navigation.topViewController;
                                                             [addBookmarkViewController prefillTitleAndForceUpdate:YES];
                                                             PresentController(navigation);
                                                         }];
                }
            }
        });
    };

    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    for (NSItemProvider *itemProvider in item.attachments) {
        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeURL]) {
            [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeURL
                                            options:0
                                  completionHandler:^(NSURL *url, NSError *error) {
                                      CompletionHandler(url.absoluteString, nil);
                                  }];
            break;
        }
        
        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePlainText]) {
            [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePlainText
                                            options:0
                                  completionHandler:^(NSString *text, NSError *error) {
                                      NSURL *url = [NSURL URLWithString:text];
                                      if (url) {
                                          CompletionHandler(text, nil);
                                      }
                                      else {
                                          CompletionHandler(nil, text);
                                      }
                                  }];
            break;
        }
        
        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePropertyList]) {
            [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePropertyList
                                            options:0
                                  completionHandler:^(NSDictionary *results, NSError *error) {
                                      CompletionHandler(results[NSExtensionJavaScriptPreprocessingResultsKey][@"url"], results[NSExtensionJavaScriptPreprocessingResultsKey][@"title"]);
                                  }];
            break;
        }
    }
}

@end

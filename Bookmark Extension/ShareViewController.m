//
//  ShareViewController.m
//  Bookmark Extension
//
//  Created by Daniel Loewenherz on 8/17/17.
//  Copyright © 2017 Lionheart Software. All rights reserved.
//

@import ASPinboard;
@import LHSCategoryCollection;
@import FMDB;
@import MobileCoreServices;

#import "ShareViewController.h"
#import "PPAddBookmarkViewController.h"
#import "PPPinboardDataSource.h"
#import "PPTheme.h"

@interface ShareViewController ()

@property (nonatomic) BOOL hasToken;

- (void)displayNoURLAlert;

@end

@implementation ShareViewController

- (instancetype)init {
    [PPTheme customizeUIElements];
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
        self.navigationBarHidden = YES;
    }
    return self;
}

- (void)handleInvalidCredentials:(UIViewController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid Token", nil)
                                                                       message:NSLocalizedString(@"Please open Pushpin to refresh your credentials.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
        }];
        [controller presentViewController:alert animated:YES completion:nil];
    });
}

- (void)presentController:(UINavigationController *)nc token:(NSString *)token {
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
                                                           [self handleInvalidCredentials:nc];
                                                       }];
        } else {
            [self handleInvalidCredentials:nc];
        }
    }];
}

- (void)completeWithURLString:(NSString *)urlString title:(NSString *)title description:(NSString *)description token:(NSString *)token {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (urlString) {
            // Check if the bookmark is already in the database.
            __block NSDictionary *post = @{@"url": urlString, @"title": title, @"description": description};
            __block NSInteger count;

            NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP];
            NSString *path = [containerURL URLByAppendingPathComponent:@"shared.db"].path;
            DLog(@"%@", path);
            [[FMDatabaseQueue databaseQueueWithPath:path] inDatabase:^(FMDatabase *db) {
                FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) AS count, * FROM bookmark WHERE url=?" withArgumentsInArray:@[urlString]];
                [results next];
                count = [results intForColumnIndex:0];

                if (count > 0) {
                    post = [PPPinboardDataSource postFromResultSet:results];
                }

                [results close];
            }];

            if (count == 0) {
                [[ASPinboard sharedInstance] bookmarkWithURL:urlString
                                                     success:^(NSDictionary *post) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             NSDictionary *bookmark = @{@"title": post[@"description"],
                                                                                        @"description": post[@"extended"],
                                                                                        @"url": urlString,
                                                                                        @"private": @([post[@"shared"] isEqualToString:@"no"]),
                                                                                        @"unread": @([post[@"toread"] isEqualToString:@"yes"]),
                                                                                        @"tags": post[@"tags"]};
                                                             UINavigationController *navigation = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:bookmark
                                                                                                                                                              update:@(YES)
                                                                                                                                                            callback:nil];
                                                             [self presentController:navigation token:token];
                                                         });
                                                     }
                                                     failure:^(NSError *error) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
                                                             BOOL readByDefault = [[sharedDefaults objectForKey:@"ReadByDefault"] boolValue];
                                                             BOOL privateByDefault = [[sharedDefaults objectForKey:@"PrivateByDefault"] boolValue];

                                                             NSDictionary *bookmark = @{
                                                                                        @"title": title,
                                                                                        @"url": urlString,
                                                                                        @"description": description,
                                                                                        @"private": @(privateByDefault),
                                                                                        @"unread": @(!readByDefault)
                                                                                        };

                                                             PPNavigationController *navigation = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:bookmark
                                                                                                                                                              update:@(NO)
                                                                                                                                                            callback:nil];

                                                             PPAddBookmarkViewController *addBookmarkViewController = (PPAddBookmarkViewController *)navigation.topViewController;

                                                             if (!title && !description) {
                                                                 [addBookmarkViewController prefillTitleAndForceUpdate:YES];
                                                             }

                                                             [self presentController:navigation token:token];
                                                         });
                                                     }];
            } else {
                UINavigationController *navigation = [PPAddBookmarkViewController addBookmarkViewControllerWithBookmark:post
                                                                                                                 update:@(YES)
                                                                                                               callback:nil];
                [self presentController:navigation token:token];
            }
        }
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    NSString *token = [sharedDefaults objectForKey:@"token"];
    DLog(@"%@", APP_GROUP);
    self.hasToken = token.length > 0;

    if (self.hasToken) {
        [[ASPinboard sharedInstance] setToken:token];
    }

    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *titleItemProvider;
    NSItemProvider *urlItemProvider;
    NSItemProvider *propertyListItemProvider;
    for (NSItemProvider *itemProvider in item.attachments) {
        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeURL]) {
            urlItemProvider = itemProvider;
            continue;
        }

        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePlainText]) {
            titleItemProvider = itemProvider;
            continue;
        }

        if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePropertyList]) {
            propertyListItemProvider = itemProvider;
            break;
        }
    }

    if (propertyListItemProvider) {
        [propertyListItemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePropertyList
                                                    options:0
                                          completionHandler:^(NSDictionary *results, NSError *error) {
                                              NSDictionary *data = results[NSExtensionJavaScriptPreprocessingResultsKey];
                                              [self completeWithURLString:data[@"url"] title:data[@"title"] description:data[@"selection"] token:token];
                                          }];
    } else if (titleItemProvider != nil || urlItemProvider != nil) {
        dispatch_group_t group = dispatch_group_create();

        __block NSString *urlString;
        __block NSString *title;

        if (urlItemProvider) {
            dispatch_group_enter(group);
            [urlItemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeURL
                                               options:0
                                     completionHandler:^(NSURL *url, NSError *error) {
                                         urlString = url.absoluteString;

                                         dispatch_group_leave(group);
                                     }];
        }

        if (titleItemProvider) {
            dispatch_group_enter(group);

            [titleItemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePlainText
                                                 options:0
                                       completionHandler:^(NSString *text, NSError *error) {
                                           NSURL *url = [NSURL URLWithString:text];
                                           if (url) {
                                               urlString = text;
                                           } else {
                                               title = text;
                                           }

                                           dispatch_group_leave(group);
                                       }];
        }

        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (title == nil) {
                title = @"";
            }

            if (urlString) {
                [self completeWithURLString:urlString title:title description:@"" token:token];
            } else {
                [self displayNoURLAlert];
            }
        });
    } else {
        [self displayNoURLAlert];
    }
}

- (void)displayNoURLAlert {
    UIAlertController *alert = [UIAlertController lhs_alertViewWithTitle:@"No URL Found" message:@"No URL was provided for this webpage. Please try using another browser. If you still experience issues, please contact support."];
    [alert lhs_addActionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

//
//  PrimaryNavigationViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 2/3/13.
//
//

#import "PrimaryNavigationViewController.h"
#import "FMDatabase.h"
#import "AddBookmarkViewController.h"

@interface PrimaryNavigationViewController ()

@end

@implementation PrimaryNavigationViewController

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)promptUserToAddBookmark {
    self.bookmarkURL = [UIPasteboard generalPasteboard].string;
    if (!self.bookmarkURL) {
        return;
    }

    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[self.bookmarkURL]];
    [results next];
    BOOL alreadyExistsInBookmarks = [results intForColumnIndex:0] == 0;
    results = [db executeQuery:@"SELECT COUNT(*) FROM rejected_bookmark WHERE url=?" withArgumentsInArray:@[self.bookmarkURL]];
    [results next];
    BOOL alreadyRejected = [results intForColumnIndex:0] != 0;
    if (alreadyExistsInBookmarks && !alreadyRejected) {
        NSURL *candidateURL = [NSURL URLWithString:self.bookmarkURL];
        if (candidateURL && candidateURL.scheme && candidateURL.host) {
            [[AppDelegate sharedDelegate] retrievePageTitle:candidateURL
                                                   callback:^(NSString *title, NSString *description) {
                                                       self.bookmarkTitle = title;
                                                       [self.addBookmarkFromClipboardAlertView show];
                                                       [mixpanel track:@"Prompted to add bookmark from clipboard"];
                                                   }];

        }
    }
    [db close];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.addBookmarkFromClipboardAlertView) {
        if (buttonIndex == 1) {
            [self showAddBookmarkViewControllerWithBookmark:@{@"url": self.bookmarkURL, @"title": self.bookmarkTitle} update:@(NO) callback:nil];
            [[Mixpanel sharedInstance] track:@"Decided to add bookmark from clipboard"];
        }
        else {
            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            [db executeUpdate:@"INSERT INTO rejected_bookmark (url) VALUES(?)" withArgumentsInArray:@[self.bookmarkURL]];
            [db close];
        }
    }
}

- (void)showAddBookmarkViewControllerWithBookmark:(NSDictionary *)bookmark update:(NSNumber *)isUpdate callback:(void (^)())callback {
    AddBookmarkViewController *addBookmarkViewController = [[AddBookmarkViewController alloc] init];
    UINavigationController *addBookmarkViewNavigationController = [[UINavigationController alloc] initWithRootViewController:addBookmarkViewController];

    if (isUpdate.boolValue) {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update Navigation Bar", nil) style:UIBarButtonItemStyleDone target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Update Bookmark Page Title", nil);
        addBookmarkViewController.urlTextField.textColor = [UIColor grayColor];
    }
    else {
        addBookmarkViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Navigation Bar", nil) style:UIBarButtonItemStylePlain target:addBookmarkViewController action:@selector(addBookmark)];
        addBookmarkViewController.title = NSLocalizedString(@"Add Bookmark Page Title", nil);
    }
    addBookmarkViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel Navigation Bar", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeModal:)];

    addBookmarkViewController.modalDelegate = self;

    if (bookmark[@"title"]) {
        addBookmarkViewController.titleTextField.text = bookmark[@"title"];
    }

    if (bookmark[@"url"]) {
        addBookmarkViewController.urlTextField.text = bookmark[@"url"];

        if (isUpdate.boolValue) {
            addBookmarkViewController.urlTextField.enabled = NO;
        }
    }

    if (bookmark[@"tags"]) {
        addBookmarkViewController.tagTextField.text = bookmark[@"tags"];
    }

    if (bookmark[@"description"]) {
        addBookmarkViewController.descriptionTextField.text = bookmark[@"description"];
    }

    if (callback) {
        addBookmarkViewController.callback = callback;
    }

    if (bookmark[@"private"]) {
        addBookmarkViewController.setAsPrivate = bookmark[@"private"];
    }
    else {
        addBookmarkViewController.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
    }

    if (bookmark[@"unread"]) {
        addBookmarkViewController.markAsRead = @(!([bookmark[@"unread"] boolValue]));
    }
    else {
        addBookmarkViewController.markAsRead = [[AppDelegate sharedDelegate] readByDefault];
    }

    [self presentViewController:addBookmarkViewNavigationController animated:YES completion:nil];
}

- (void)showAddBookmarkViewController {
    [self showAddBookmarkViewControllerWithBookmark:@{} update:@(NO) callback:^{}];
}

@end

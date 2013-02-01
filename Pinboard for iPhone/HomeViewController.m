//
//  HomeViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ASPinboard/ASPinboard.h>
#import "HomeViewController.h"
#import "BookmarkViewController.h"
#import "BookmarkFeedViewController.h"
#import "AppDelegate.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

@synthesize connectionAvailable;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.connectionAvailable = [[[AppDelegate sharedDelegate] connectionAvailable] boolValue];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusDidChange:) name:@"ConnectionStatusDidChangeNotification" object:nil];

    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![delegate feedToken]) {
        [delegate setNetworkActivityIndicatorVisible:YES];
        [[ASPinboard sharedPinboard] retrieveRSSKey:^(NSString *feedToken) {
                                                [delegate setNetworkActivityIndicatorVisible:NO];
                                                [delegate setToken:feedToken];
                                                [self.tableView reloadData];
                                            }
                                            failure:^{
                                                [delegate setNetworkActivityIndicatorVisible:NO];
                                            }];
    }
}

- (void)connectionStatusDidChange:(NSNotification *)notification {
    BOOL oldConnectionAvailable = self.connectionAvailable;
    self.connectionAvailable = [[[AppDelegate sharedDelegate] connectionAvailable] boolValue];
    if (oldConnectionAvailable != self.connectionAvailable) {
        [self.tableView beginUpdates];
        if (self.connectionAvailable) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.connectionAvailable) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (self.connectionAvailable) {
                return 6;
            }
            else {
                return 5;
            }
            break;
        case 1:
            return 5;
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Personal", nil);
            break;
        case 1:
            return NSLocalizedString(@"Community", nil);
            break;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    
    FMResultSet *results;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark"];
                    [results next];

                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    cell.detailTextLabel.text = [results stringForColumnIndex:0];
                    break;
                case 1:
                    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private = ?" withArgumentsInArray:@[@(YES)]];
                    [results next];

                    cell.textLabel.text = NSLocalizedString(@"Private Bookmarks", nil);
                    cell.detailTextLabel.text = [results stringForColumnIndex:0];
                    break;  
                case 2:
                    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE private = ?" withArgumentsInArray:@[@(NO)]];
                    [results next];

                    cell.textLabel.text = NSLocalizedString(@"Public", nil);
                    cell.detailTextLabel.text = [results stringForColumnIndex:0];
                    break;
                case 3:
                    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE unread = ?" withArgumentsInArray:@[@(YES)]];
                    [results next];

                    cell.textLabel.text = NSLocalizedString(@"Unread", nil);
                    cell.detailTextLabel.text = [results stringForColumnIndex:0];
                    break;
                case 4:
                    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE tags = ''"];
                    [results next];

                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.detailTextLabel.text = [results stringForColumnIndex:0];
                    break;
                case 5:
                    cell.textLabel.text = NSLocalizedString(@"Starred", nil);
                    cell.detailTextLabel.text = @"";
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Network", nil);
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Popular", nil);
                    break;
                case 2:
                    cell.textLabel.text = @"Wikipedia";
                    break;
                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Fandom", nil);
                    break;
                case 4:
                    cell.textLabel.text = @"日本語";
                    break;
            }
            cell.detailTextLabel.text = @"";

            break;   
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    switch (indexPath.section) {
        case 0: {
            id bookmarkViewController;

            switch (indexPath.row) {
                case 0:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithFilters:@[] parameters:parameters];
                    [(BookmarkViewController *)bookmarkViewController setTitle:NSLocalizedString(@"All Bookmarks", nil)];
                    [mixpanel track:@"Browsed all bookmarks"];
                    break;
                case 1:
                    parameters[@"private"] = @(YES);
                    bookmarkViewController = [[BookmarkViewController alloc] initWithFilters:@[@"private"] parameters:parameters];
                    [(BookmarkViewController *)bookmarkViewController setTitle:NSLocalizedString(@"Private Bookmarks", nil)];
                    [mixpanel track:@"Browsed private bookmarks"];
                    break;
                case 2:
                    parameters[@"private"] = @(NO);
                    bookmarkViewController = [[BookmarkViewController alloc] initWithFilters:@[@"private"] parameters:parameters];
                    [(BookmarkViewController *)bookmarkViewController setTitle:NSLocalizedString(@"Public", nil)];
                    [mixpanel track:@"Browsed public bookmarks"];
                    break;
                case 3:
                    parameters[@"unread"] = @(YES);
                    bookmarkViewController = [[BookmarkViewController alloc] initWithFilters:@[@"unread"] parameters:parameters];
                    [(BookmarkViewController *)bookmarkViewController setTitle:NSLocalizedString(@"Unread", nil)];
                    [mixpanel track:@"Browsed unread bookmarks"];
                    break;
                case 4:
                    parameters[@"tags"] = @"";
                    bookmarkViewController = [[BookmarkViewController alloc] initWithFilters:@[@"tags"] parameters:parameters];
                    [(BookmarkViewController *)bookmarkViewController setTitle:NSLocalizedString(@"Untagged", nil)];
                    [mixpanel track:@"Browsed untagged bookmarks"];
                    break;
                case 5: {
                    NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                    NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                    NSString *url = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/starred/", feedToken, username];
                    bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:url];
                    [(BookmarkFeedViewController *)bookmarkViewController setTitle:NSLocalizedString(@"Starred", nil)];
                    [mixpanel track:@"Browsed starred bookmarks"];
                    break;
                }
            }

            [self.navigationController pushViewController:bookmarkViewController animated:YES];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case 1: {
            BookmarkFeedViewController *bookmarkViewController;
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil) message:@"You can't browse popular feeds unless you have an active Internet connection." delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            }
            else {
                switch (indexPath.row) {
                    case 0: {
                        NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                        NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
                        NSString *url = [NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/network/", feedToken, username];
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:url];
                        bookmarkViewController.title = NSLocalizedString(@"Network", nil);
                        [mixpanel track:@"Browsed network bookmarks"];
                        break;
                    }
                    case 1:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular"];
                        bookmarkViewController.title = NSLocalizedString(@"Popular", nil);
                        [mixpanel track:@"Browsed popular bookmarks"];
                        break;
                    case 2:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular/wikipedia"];
                        bookmarkViewController.title = @"Wikipedia";
                        [mixpanel track:@"Browsed wikipedia bookmarks"];
                        break;
                    case 3:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular/fandom"];
                        bookmarkViewController.title = NSLocalizedString(@"Fandom", nil);
                        [mixpanel track:@"Browsed fandom bookmarks"];
                        break;
                    case 4:
                        bookmarkViewController = [[BookmarkFeedViewController alloc] initWithURL:@"https://feeds.pinboard.in/json/popular/japanese"];
                        bookmarkViewController.title = @"日本語";
                        [mixpanel track:@"Browsed 日本語 bookmarks"];
                        break;
                }
                [self.navigationController pushViewController:bookmarkViewController animated:YES];
                break;
            }
        }
    }
}

@end

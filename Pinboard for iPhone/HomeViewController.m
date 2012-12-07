//
//  HomeViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HomeViewController.h"
#import "BookmarkViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 5;
            break;
        case 1:
            return 4;
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Bookmarks", nil);
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

    NSError *error = nil;
    
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

                    cell.textLabel.text = NSLocalizedString(@"Private", nil);
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
                    results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE bookmark.id NOT IN (SELECT bookmark_id FROM tagging)"];
                    [results next];

                    cell.textLabel.text = NSLocalizedString(@"Untagged", nil);
                    cell.detailTextLabel.text = [results stringForColumnIndex:0];
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"All", nil);
                    break;
                case 1:
                    cell.textLabel.text = @"Wikipedia";
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Fandom", nil);
                    break;
                case 3:
                    cell.textLabel.text = @"日本語";
                    break;
            }
            break;   
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BookmarkViewController *bookmarkViewController;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:parameters];
                    bookmarkViewController.title = NSLocalizedString(@"All Bookmarks", nil);
                    break;
                case 1:
                    parameters[@"private"] = @(YES);
                    bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark WHERE private = :private ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:parameters];
                    bookmarkViewController.title = NSLocalizedString(@"Private", nil);
                    break;
                case 2:
                    parameters[@"private"] = @(NO);
                    bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark WHERE private = :private ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:parameters];
                    bookmarkViewController.title = NSLocalizedString(@"Public", nil);
                    break;
                case 3:
                    parameters[@"unread"] = @(YES);
                    bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark WHERE unread = :unread ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:parameters];
                    bookmarkViewController.title = NSLocalizedString(@"Unread", nil);
                    break;
                case 4:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT * FROM bookmark WHERE bookmark.id NOT IN (SELECT bookmark_id FROM tagging) ORDER BY created_at DESC LIMIT :limit OFFSET :offset" parameters:parameters];
                    bookmarkViewController.title = NSLocalizedString(@"Untagged", nil);
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    break;
                case 1:
                    break;
                case 2:
                    break;
                case 3:
                    break;
            }
            break;
        }
    }
    
    [self.navigationController pushViewController:bookmarkViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

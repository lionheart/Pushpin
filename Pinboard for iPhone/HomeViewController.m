//
//  HomeViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HomeViewController.h"
#import "BookmarkViewController.h"
#import "ASManagedObject.h"

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
            return @"Bookmarks";
            break;
        case 1:
            return @"Community";
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
    
    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
    NSUInteger count;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"All";
                    count = [context countForFetchRequest:request error:&error];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", count];
                    break;
                case 1:
                    cell.textLabel.text = @"Private";

                    [request setPredicate:[NSPredicate predicateWithFormat:@"shared = NO"]];
                    count = [context countForFetchRequest:request error:&error];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", count];
                    break;  
                case 2:
                    cell.textLabel.text = @"Public";
                    [request setPredicate:[NSPredicate predicateWithFormat:@"shared = YES"]];
                    count = [context countForFetchRequest:request error:&error];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", count];
                    break;
                case 3:
                    cell.textLabel.text = @"Unread";
                    [request setPredicate:[NSPredicate predicateWithFormat:@"read = NO"]];
                    count = [context countForFetchRequest:request error:&error];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", count];
                    break;
                case 4:
                    cell.textLabel.text = @"Untagged";
                    [request setPredicate:[NSPredicate predicateWithFormat:@"tags.@count = 0"]];
                    count = [context countForFetchRequest:request error:&error];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", count];
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"All";
                    break;
                case 1:
                    cell.textLabel.text = @"Wikipedia";
                    break;
                case 2:
                    cell.textLabel.text = @"Fandom";
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

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithPredicate:nil];
                    bookmarkViewController.title = @"All Bookmarks";
                    break;
                case 1:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithPredicate:[NSPredicate predicateWithFormat:@"shared = NO"]];
                    bookmarkViewController.title = @"Private";
                    break;
                case 2:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithPredicate:[NSPredicate predicateWithFormat:@"shared = YES"]];
                    bookmarkViewController.title = @"Public";
                    break;
                case 3:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithPredicate:[NSPredicate predicateWithFormat:@"read = NO"]];
                    bookmarkViewController.title = @"Unread";
                    break;
                case 4:
                    bookmarkViewController = [[BookmarkViewController alloc] initWithPredicate:[NSPredicate predicateWithFormat:@"tags.@count = 0"]];
                    bookmarkViewController.title = @"Untagged";
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

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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 6;
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
            return @"Personal";
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
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"All";
                    cell.detailTextLabel.text = @"1209";
                    break;
                case 1:
                    cell.textLabel.text = @"Private";
                    cell.detailTextLabel.text = @"829";
                    break;  
                case 2:
                    cell.textLabel.text = @"Public";
                    cell.detailTextLabel.text = @"104";
                    break;
                case 3:
                    cell.textLabel.text = @"Unread";
                    cell.detailTextLabel.text = @"14";
                    break;
                case 4:
                    cell.textLabel.text = @"Untagged";
                    cell.detailTextLabel.text = @"323";
                    break;
                case 5:
                    cell.textLabel.text = @"Custom";
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
    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithStyle:UITableViewStylePlain url:@"" parameters:nil];
    [self.navigationController pushViewController:bookmarkViewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

//
//  GenericPostViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import "GenericPostViewController.h"
#import "BookmarkCell.h"

@interface GenericPostViewController ()

@end

@implementation GenericPostViewController

@synthesize postDataSource;

- (void)update {
    [self.postDataSource updatePosts:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            });
        });
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.postDataSource numberOfPosts];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.postDataSource heightForPostAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    NSAttributedString *string;
    NSDictionary *post;
    
    if (tableView.isEditing) {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (tableView == self.tableView) {
        string = [self.postDataSource stringForPostAtIndex:indexPath.row];
        post = [self.postDataSource postAtIndex:indexPath.row];
    }
    else {
        string = self.filteredStrings[indexPath.row];
        post = self.filteredBookmarks[indexPath.row];
    }
    
    [cell.textView setText:string];
    
    for (NSDictionary *link in [self.postDataSource linksForPost:post]) {
        [cell.textView addLinkToURL:link[@"url"] withRange:NSMakeRange([link[@"location"] integerValue], [link[@"length"] integerValue])];
    }
    
    for (id subview in [cell.contentView subviews]) {
        if (![subview isKindOfClass:[TTTAttributedLabel class]]) {
            [subview removeFromSuperview];
        }
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-40, 0, 360, [self.postDataSource heightForPostAtIndex:indexPath.row])];
    
    if ([post[@"private"] boolValue] == YES) {
        cell.textView.backgroundColor = HEX(0xddddddff);
        label.backgroundColor = HEX(0xddddddff);
    }
    else {
        cell.textView.backgroundColor = HEX(0xffffffff);
        label.backgroundColor = HEX(0xffffffff);
    }
    
    if (tableView == self.tableView) {
        [cell.contentView addSubview:label];
        [cell.contentView sendSubviewToBack:label];
    }
    
    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end

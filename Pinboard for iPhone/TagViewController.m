//
//  TagViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

#import "TagViewController.h"
#import "Tag.h"
#import "BookmarkViewController.h"
#import "FMDatabase.h"

@interface TagViewController ()

@end

@implementation TagViewController

@synthesize titleToTags;
@synthesize alphabet;
@synthesize sortedTitles;
@synthesize searchDisplayController;
@synthesize searchBar = _searchBar;
@synthesize filteredTags;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];

    self.titleToTags = [NSMutableDictionary dictionary];

    self.titleToTags = [@{@"#": [NSMutableArray array], @"A": [NSMutableArray array], @"B": [NSMutableArray array], @"C": [NSMutableArray array], @"D": [NSMutableArray array], @"E": [NSMutableArray array], @"F": [NSMutableArray array], @"G": [NSMutableArray array], @"H": [NSMutableArray array], @"I": [NSMutableArray array], @"J": [NSMutableArray array], @"K": [NSMutableArray array], @"L": [NSMutableArray array], @"M": [NSMutableArray array], @"N": [NSMutableArray array], @"O": [NSMutableArray array], @"P": [NSMutableArray array], @"Q": [NSMutableArray array], @"R": [NSMutableArray array], @"S": [NSMutableArray array], @"T": [NSMutableArray array], @"U": [NSMutableArray array], @"V": [NSMutableArray array], @"W": [NSMutableArray array], @"X": [NSMutableArray array], @"Y": [NSMutableArray array], @"Z": [NSMutableArray array]} mutableCopy];

    FMResultSet *results = [db executeQuery:@"SELECT * FROM tag ORDER BY name ASC"];
    NSString *name;
    while ([results next]) {
        name = [results stringForColumn:@"name"];
        if (name.length == 0) {
            continue;
        }

        NSString *firstLetter = [[name substringToIndex:1] uppercaseString];
        if (![self.titleToTags objectForKey:firstLetter]) {
            firstLetter = @"#";
        }

        NSMutableArray *temp = [self.titleToTags objectForKey:firstLetter];
        [temp addObject:@{@"name": name, @"id": @([results intForColumn:@"id"])}];
        [self.titleToTags setObject:temp forKey:firstLetter];
    }

    self.sortedTitles = @[UITableViewIndexSearch, @"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setContentOffset:CGPointMake(0,self.searchDisplayController.searchBar.frame.size.height)];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0) {
            return 0;
        }
        else {
            NSString *key = self.sortedTitles[section];
            return [(NSMutableArray *)self.titleToTags[key] count];
        }
    }
    else {
        if (section == 0) {
            return [self.filteredTags count];
        }
        else {
            return 0;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return [self.sortedTitles count];
    }
    else {
        return 1;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    }
    else {
        return self.sortedTitles;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (title == UITableViewIndexSearch) {
        [tableView scrollRectToVisible:CGRectMake(0, 0, self.searchBar.frame.size.width, self.searchBar.frame.size.height) animated:NO];
        return -1;
    }
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && !self.searchDisplayController.active && section > 0) {
        return self.sortedTitles[section];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TagCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    NSDictionary *tag;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        tag = self.filteredTags[indexPath.row];
    }
    else {
        tag = self.titleToTags[[self tableView:tableView titleForHeaderInSection:indexPath.section]][indexPath.row];
    }

    cell.textLabel.text = tag[@"name"];
    return cell;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"%@", searchBar.text);
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *result = [db executeQuery:@"SELECT * FROM tag_fts WHERE tag_fts.name MATCH ?" withArgumentsInArray:@[[searchText stringByAppendingString:@"*"]]];
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    while ([result next]) {
        [tags addObject:@{@"id": @([result intForColumn:@"id"]), @"name": [result stringForColumn:@"name"]}];
    }
    [db close];
    self.filteredTags = tags;
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *tag;
    if (tableView == self.tableView) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = self.titleToTags[[self tableView:tableView titleForHeaderInSection:indexPath.section]][indexPath.row];
    }
    else {
        [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
        tag = self.filteredTags[indexPath.row];
    }
    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT bookmark.* FROM bookmark LEFT JOIN tagging ON bookmark.id = tagging.bookmark_id LEFT JOIN tag ON tag.id = tagging.tag_id WHERE tag.id = :tag_id LIMIT :limit OFFSET :offset" parameters:[NSMutableDictionary dictionaryWithObjectsAndKeys:tag[@"id"], @"tag_id", nil]];
    bookmarkViewController.title = tag[@"name"];
    [self.navigationController pushViewController:bookmarkViewController animated:YES];
}

@end

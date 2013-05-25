//
//  TagViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/1/12.
//
//

#import "TagViewController.h"
#import "FMDatabase.h"
#import "PPCoreGraphics.h"
#import "GenericPostViewController.h"
#import "PinboardDataSource.h"

@interface TagViewController ()

@end

@implementation TagViewController

@synthesize titleToTags;
@synthesize alphabet;
@synthesize sortedTitles;
@synthesize searchDisplayController = __searchDisplayController;
@synthesize searchBar = _searchBar;
@synthesize filteredTags;
@synthesize navigationController;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.opaque = NO;
        self.tableView.backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];

    self.titleToTags = [NSMutableDictionary dictionary];

    self.titleToTags = [@{@"#": [NSMutableArray array], @"A": [NSMutableArray array], @"B": [NSMutableArray array], @"C": [NSMutableArray array], @"D": [NSMutableArray array], @"E": [NSMutableArray array], @"F": [NSMutableArray array], @"G": [NSMutableArray array], @"H": [NSMutableArray array], @"I": [NSMutableArray array], @"J": [NSMutableArray array], @"K": [NSMutableArray array], @"L": [NSMutableArray array], @"M": [NSMutableArray array], @"N": [NSMutableArray array], @"O": [NSMutableArray array], @"P": [NSMutableArray array], @"Q": [NSMutableArray array], @"R": [NSMutableArray array], @"S": [NSMutableArray array], @"T": [NSMutableArray array], @"U": [NSMutableArray array], @"V": [NSMutableArray array], @"W": [NSMutableArray array], @"X": [NSMutableArray array], @"Y": [NSMutableArray array], @"Z": [NSMutableArray array]} mutableCopy];

    FMResultSet *results = [db executeQuery:@"SELECT id, name, count FROM tag ORDER BY name ASC"];
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
        [temp addObject:@{@"name": name, @"id": @([results intForColumn:@"id"]), @"count": [results stringForColumn:@"count"]}];
        [self.titleToTags setObject:temp forKey:firstLetter];
    }

    self.sortedTitles = @[UITableViewIndexSearch, @"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setContentOffset:CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Opened tags"];
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
        [tableView scrollRectToVisible:CGRectMake(0, 0, self.searchBar.frame.size.width, self.searchBar.frame.size.height) animated:YES];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && !self.searchDisplayController.active && section > 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        view.clipsToBounds = YES;
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(20, 0, 320, 44);
        label.font = [UIFont fontWithName:@"Avenir-Medium" size:18];
        label.textColor = HEX(0x4C586AFF);
        label.backgroundColor = HEX(0xF7F9FDff);
        label.text = self.sortedTitles[section];
        [view addSubview:label];
        return view;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section > 0) {
        return 44;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TagCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    NSArray *subviews = [cell.contentView subviews];
    for (id subview in subviews) {
        [subview removeFromSuperview];
    }

    cell.textLabel.textColor = HEX(0x33353Bff);
    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
    cell.backgroundColor = [UIColor whiteColor];
    
    NSDictionary *tag;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        tag = self.filteredTags[indexPath.row];
    }
    else {
        tag = self.titleToTags[[self tableView:tableView titleForHeaderInSection:indexPath.section]][indexPath.row];
    }

    cell.textLabel.text = tag[@"name"];
    
    UIImage *pillImage = [PPCoreGraphics pillImage:tag[@"count"]];
    UIImageView *pillView = [[UIImageView alloc] initWithImage:pillImage];
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        pillView.frame = CGRectMake(320 - pillImage.size.width - 5, (cell.contentView.frame.size.height - pillImage.size.height) / 2, pillImage.size.width, pillImage.size.height);
    }
    else {
        pillView.frame = CGRectMake(320 - pillImage.size.width - 45, (cell.contentView.frame.size.height - pillImage.size.height) / 2, pillImage.size.width, pillImage.size.height);
    }
    [cell.contentView addSubview:pillView];
    return cell;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
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
    FMResultSet *result = [db executeQuery:@"SELECT id, name, count FROM tag WHERE id in (SELECT tag_fts.id FROM tag_fts WHERE tag_fts.name MATCH ?)" withArgumentsInArray:@[[searchText stringByAppendingString:@"*"]]];
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    while ([result next]) {
        [tags addObject:@{@"id": @([result intForColumn:@"id"]), @"name": [result stringForColumn:@"name"], @"count": [result stringForColumn:@"count"]}];
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
    
    GenericPostViewController *postViewController = [[GenericPostViewController alloc] init];
    PinboardDataSource *pinboardDataSource = [[PinboardDataSource alloc] init];
    pinboardDataSource.query = @"SELECT * FROM bookmark WHERE id IN (SELECT bookmark_id FROM tagging WHERE tag_id=:tag_id) ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
    pinboardDataSource.queryParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"limit": @100, @"offset": @0, @"tag_id": tag[@"id"]}];
    postViewController.postDataSource = pinboardDataSource;
    postViewController.title = tag[@"name"];

    [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
}

@end

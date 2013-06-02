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
#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

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
    
    NSArray *letters = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];

    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];

    self.titleToTags = [NSMutableDictionary dictionary];

    FMResultSet *results = [db executeQuery:@"SELECT name, count FROM tag ORDER BY name ASC"];
    NSString *name;
    while ([results next]) {
        name = [results stringForColumn:@"name"];
        if (name.length == 0) {
            continue;
        }

        NSString *firstLetter = [[name substringToIndex:1] uppercaseString];
        if (![letters containsObject:firstLetter]) {
            firstLetter = @"#";
        }

        NSMutableArray *temp = [self.titleToTags objectForKey:firstLetter];
        if (!temp) {
            temp = [NSMutableArray array];
        }
        [temp addObject:@{@"name": name, @"count": [results stringForColumn:@"count"]}];
        [self.titleToTags setObject:temp forKey:firstLetter];
    }

    NSArray *newSortedTitles = [[self.titleToTags allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    NSMutableArray *newSortedTitlesWithSearch = [NSMutableArray arrayWithObject:UITableViewIndexSearch];
    for (NSString *title in newSortedTitles) {
        [newSortedTitlesWithSearch addObject:title];
    }

    self.sortedTitles = newSortedTitlesWithSearch;
    self.filteredTags = [NSMutableArray array];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setContentOffset:CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    if ([self.searchDisplayController isActive]) {
        return nil;
    }
    else {
        return self.sortedTitles;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (tableView == self.tableView) {
        if (title == UITableViewIndexSearch) {
            [tableView scrollRectToVisible:CGRectMake(0, 0, self.searchBar.frame.size.width, self.searchBar.frame.size.height) animated:YES];
            return -1;
        }
        return index;
    }
    return 0;
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
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    NSArray *subviews = [cell.contentView subviews];
    for (id subview in subviews) {
        [subview removeFromSuperview];
    }

    if (tableView == self.tableView) {
        CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
        if (indexPath.row > 0) {
            [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayer]];
        }

        if (indexPath.row < 5) {
            [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
        }
        [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];
    }
    else {
        [cell setSelectedBackgroundViewWithLayer:[PPGroupedTableViewCell layerForNonGroupedBackground]];
    }

    
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

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *result = [db executeQuery:@"SELECT name, count FROM tag WHERE name in (SELECT tag_fts.name FROM tag_fts WHERE tag_fts.name MATCH ?) ORDER BY count DESC" withArgumentsInArray:@[[searchText stringByAppendingString:@"*"]]];

        NSMutableArray *newTagNames = [NSMutableArray array];
        NSMutableArray *oldTagNames = [NSMutableArray array];
        
        __block NSMutableArray *indexPathsToRemove = [NSMutableArray array];
        __block NSMutableArray *indexPathsToAdd = [NSMutableArray array];
        __block NSMutableArray *indexPathsToReload = [NSMutableArray array];
        __block NSMutableArray *newTags = [[NSMutableArray alloc] init];
        NSString *tagName;
        NSInteger index = 0;

        for (NSDictionary *tag in self.filteredTags) {
            [oldTagNames addObject:tag[@"name"]];
        }

        while ([result next]) {
            tagName = [result stringForColumn:@"name"];
            [newTags addObject:@{@"name": [result stringForColumn:@"name"], @"count": [result stringForColumn:@"count"]}];
            [newTagNames addObject:tagName];
            
            if (![oldTagNames containsObject:tagName]) {
                [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            }
            index++;
        }
        [db close];
        
        NSInteger i;
        for (i=0; i<oldTagNames.count; i++) {
            if (![newTagNames containsObject:oldTagNames[i]]) {
                [indexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.searchDisplayController.searchResultsTableView beginUpdates];
            self.filteredTags = newTags;
            [self.searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
            [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationFade];
            [self.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
            [self.searchDisplayController.searchResultsTableView endUpdates];
        });
    });
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
    [pinboardDataSource filterByPrivate:nil isRead:nil isStarred:nil hasTags:nil tags:@[tag[@"name"]] offset:0 limit:50];
    postViewController.postDataSource = pinboardDataSource;
    postViewController.title = tag[@"name"];
    [[AppDelegate sharedDelegate].navigationController pushViewController:postViewController animated:YES];
}

@end

//
//  NoteViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/8/12.
//
//

#import "NoteViewController.h"
#import "AppDelegate.h"

#import <ASPinboard/ASPinboard.h>

@interface NoteViewController ()

@end

@implementation NoteViewController

// We have to re-synthesize this, because UITableViewController already has a searchDisplayController property. Confusing, right? Remove it and you'll understand.
@synthesize searchDisplayController;
@synthesize notes = _notes;

#pragma mark - Table view data source

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    [[ASPinboard sharedInstance] notesWithSuccess:^(NSArray *notes) {
        self.notes = notes;
        [mixpanel.people set:@"Notes" to:@(self.notes.count)];
        [self.tableView reloadData];
    }];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchDisplayController.searchBar.frame))];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Opened notes"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self.notes count];
    }
    else {
        return [self.filteredNotes count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }

    if (tableView == self.tableView) {
        cell.textLabel.text = self.notes[indexPath.row][@"title"];
    }
    else {
        cell.textLabel.text = self.filteredNotes[indexPath.row][@"title"];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    if (![[AppDelegate sharedDelegate] connectionAvailable]) {
        return;
    }

    NSDictionary *note;
    if (tableView == self.tableView) {
        note = self.notes[indexPath.row];
    }
    else {
        note = self.filteredNotes[indexPath.row];
    }
    
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard noteWithId:note[@"id"]
                 success:^(NSString *title, NSString *text) {
                     self.webView = [[UIWebView alloc] init];
                     [self.webView loadHTMLString:[NSString stringWithFormat:@"<body><div style='font-family:Helvetica;'><h4>%@</h4></div></body>", text] baseURL:nil];
                    
                     self.noteDetailViewController = [[UIViewController alloc] init];
                     self.noteDetailViewController.title = title;
                     self.webView.frame = self.noteDetailViewController.view.frame;
                     self.noteDetailViewController.view = self.webView;
                     self.noteDetailViewController.hidesBottomBarWhenPushed = YES;
                     [tableView deselectRowAtIndexPath:indexPath animated:YES];
                     [mixpanel track:@"Viewed note details"];
                     [self.navigationController pushViewController:self.noteDetailViewController animated:YES];
                 }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.filteredNotes = [NSMutableArray array];
    for (NSDictionary *note in self.notes) {
        if ([note[@"title"] rangeOfString:searchText].location != NSNotFound) {
            [self.filteredNotes addObject:note];
        }
    }
    [self.tableView reloadData];
}

@end

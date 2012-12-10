//
//  NoteViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/8/12.
//
//

#import "NoteViewController.h"
#import "AppDelegate.h"

@interface NoteViewController ()

@end

@implementation NoteViewController

@synthesize searchDisplayController;
@synthesize notes;
@synthesize searchBar;
@synthesize noteDetailViewController;
@synthesize webView;

#pragma mark - Table view data source

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSString *endpoint = [NSString stringWithFormat:@"https://api.pinboard.in/v1/notes/list?format=json&auth_token=%@", [[AppDelegate sharedDelegate] token]];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                               NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                               self.notes = payload[@"notes"];
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
    [self.tableView setContentOffset:CGPointMake(0,self.searchDisplayController.searchBar.frame.size.height)];
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
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSString *noteURLString = [NSString stringWithFormat:@"https://api.pinboard.in/v1/notes/%@?format=json&auth_token=%@", note[@"id"], [[AppDelegate sharedDelegate] token]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:noteURLString]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                               if (!error) {
                                   NSDictionary *noteInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

                                   self.webView = [[UIWebView alloc] init];
                                   [self.webView loadHTMLString:[NSString stringWithFormat:@"<body><div style='font-family:Helvetica;'><h4>%@</h4></div></body>", noteInfo[@"text"]] baseURL:nil];

                                   self.noteDetailViewController = [[UIViewController alloc] init];
                                   self.noteDetailViewController.title = noteInfo[@"title"];
                                   self.webView.frame = self.noteDetailViewController.view.frame;
                                   self.noteDetailViewController.view = self.webView;
                                   self.noteDetailViewController.hidesBottomBarWhenPushed = YES;
                                   [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                   [mixpanel track:@"Viewed note details"];
                                   [self.navigationController pushViewController:self.noteDetailViewController animated:YES];
                               }
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

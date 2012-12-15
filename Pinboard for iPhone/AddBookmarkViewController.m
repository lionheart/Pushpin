//
//  AddBookmarkViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import "AddBookmarkViewController.h"
#import "NSString+URLEncoding.h"
#import "FMDatabase.h"

@interface AddBookmarkViewController ()

@end

@implementation AddBookmarkViewController

@synthesize modalDelegate;
@synthesize urlTextField;
@synthesize descriptionTextField;
@synthesize titleTextField;
@synthesize tagTextField;
@synthesize privateSwitch;
@synthesize readSwitch;
@synthesize markAsRead;
@synthesize setAsPrivate;
@synthesize tagCompletions;
@synthesize currentTextField;
@synthesize callback;

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.urlTextField = [[UITextField alloc] init];
        self.urlTextField.font = [UIFont systemFontOfSize:16];
        self.urlTextField.delegate = self;
        self.urlTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.urlTextField.placeholder = @"https://pinboard.in/";
        self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.urlTextField.text = @"";
        
        self.descriptionTextField = [[UITextField alloc] init];
        self.descriptionTextField.font = [UIFont systemFontOfSize:16];
        self.descriptionTextField.delegate = self;
        self.descriptionTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.descriptionTextField.placeholder = @"";
        self.descriptionTextField.text = @"";
        
        self.titleTextField = [[UITextField alloc] init];
        self.titleTextField.font = [UIFont systemFontOfSize:16];
        self.titleTextField.delegate = self;
        self.titleTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.titleTextField.placeholder = NSLocalizedString(@"Add bookmark title example", nil);
        self.titleTextField.text = @"";
        
        self.tagTextField = [[UITextField alloc] init];
        self.tagTextField.font = [UIFont systemFontOfSize:16];
        self.tagTextField.delegate = self;
        self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.tagTextField.placeholder = NSLocalizedString(@"Add bookmark tag example", nil);
        self.tagTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tagTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tagTextField.text = @"";
        
        self.markAsRead = @(NO);
        self.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
        
        self.callback = ^(void) {};
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tagCompletions = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 4) {
        return 2;
    }
    else if (section == 3) {
        return 1 + self.tagCompletions.count;
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3 && indexPath.row > 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        NSString *stringToReplace = [[self.tagTextField.text componentsSeparatedByString:@" "] lastObject];
        NSRange range = NSMakeRange([self.tagTextField.text length] - [stringToReplace length], [stringToReplace length]);
        self.tagTextField.text = [self.tagTextField.text stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@ ", self.tagCompletions[indexPath.row - 1]]];
        [self searchUpdatedWithRange:NSMakeRange(0, 0) andString:nil];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return NSLocalizedString(@"Separate tags with spaces", nil);
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [NSString stringWithFormat:@"🌐 %@", NSLocalizedString(@"URL", nil)];
            break;
        case 1:
            return [NSString stringWithFormat:@"📝 %@", NSLocalizedString(@"Title", nil)];
            break;
        case 2:
            return [NSString stringWithFormat:@"📰 %@", NSLocalizedString(@"Description", nil)];
            break;
        case 3:
            return [NSString stringWithFormat:@"🔖 %@", NSLocalizedString(@"Tags", nil)];
            break;
        case 4:
            return NSLocalizedString(@"Other", nil);
            break;
        default:
            break;
    }
    return @"";
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.currentTextField = textField;
    
    if (self.currentTextField == self.tagTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.descriptionTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.titleTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.urlTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    return YES;
}

- (void)keyboardDidShow:(NSNotification *)sender {
    if (self.currentTextField == self.tagTextField) {
        CGSize kbSize = [[[sender userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        UIEdgeInsets insets = self.tableView.contentInset;
        insets.bottom = kbSize.height;
        self.tableView.contentInset = insets;
    }
    
    if (self.currentTextField == self.tagTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.descriptionTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.titleTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if (self.currentTextField == self.urlTextField) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)keyboardDidHide:(NSNotification *)sender {
    self.tableView.contentInset = UIEdgeInsetsZero;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.callback();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)searchUpdatedWithRange:(NSRange)range andString:(NSString *)string {
    NSInteger index = 1;
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    while (index <= self.tagCompletions.count) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:3]];
        index++;
    }
    
    [self.tagCompletions removeAllObjects];
    
    [self.tableView beginUpdates];
    if ([indexPaths count] > 0) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [indexPaths removeAllObjects];
    }

    if (string != nil && ![string isEqualToString:@" "] && (range.length - string.length <= 1 || string.length - range.length <= 1)) {
       
        NSString *newTextFieldContents;
        if (range.length > string.length) {
            newTextFieldContents = [self.tagTextField.text substringToIndex:self.tagTextField.text.length - range.length];
        }
        else {
            newTextFieldContents = [NSString stringWithFormat:@"%@", self.tagTextField.text];
        }

        NSString *searchString = [[[newTextFieldContents componentsSeparatedByString:@" "] lastObject] stringByAppendingFormat:@"%@*", string];

        FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
        [db open];
        FMResultSet *result = [db executeQuery:@"SELECT tag_fts.name FROM tag_fts, tag WHERE tag.id=tag_fts.id AND tag_fts.name MATCH ? ORDER BY tag.count DESC LIMIT 4" withArgumentsInArray:@[searchString]];
        
        index = 1;
        while ([result next]) {
            [self.tagCompletions addObject:[result stringForColumn:@"name"]];
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:3]];
            index++;
        }
        
        [db close];
        
        if ([indexPaths count] > 0) {
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    [self.tableView endUpdates];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagTextField) {
        [self searchUpdatedWithRange:range andString:string];
    }
    else if (textField == self.urlTextField) {
        if ([string isEqualToString:@" "]) {
            return NO;
        }
    }
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"";
    
    for (UIView *view in [cell.contentView subviews]) {
        [view removeFromSuperview];
    }

    if (indexPath.section < 5) {
        CGRect frame = cell.frame;

        switch (indexPath.section) {
            case 0:
                self.urlTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 300, 31);
                [cell.contentView addSubview:self.urlTextField];
                break;
                
            case 1:
                self.titleTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 300, 31);
                [cell.contentView addSubview:self.titleTextField];
                break;
                
            case 2:
                self.descriptionTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 300, 31);
                [cell.contentView addSubview:self.descriptionTextField];
                break;
                
            case 3:
                if (indexPath.row == 0) {
                    self.tagTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 300, 31);
                    [cell.contentView addSubview:self.tagTextField];
                }
                else {
                    cell.textLabel.text = self.tagCompletions[indexPath.row - 1];
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.editing = NO;
                }
                break;
                
            case 4: {
                if (indexPath.row == 0) {
                    if (self.setAsPrivate.boolValue) {
                        cell.textLabel.text = [NSString stringWithFormat:@"🔒 %@", NSLocalizedString(@"Set as private?", nil)];
                    }
                    else {
                        cell.textLabel.text = [NSString stringWithFormat:@"🔓 %@", NSLocalizedString(@"Set as private?", nil)];
                    }

                    self.privateSwitch = [[UISwitch alloc] init];
                    CGSize size = cell.frame.size;
                    CGSize switchSize = self.privateSwitch.frame.size;
                    self.privateSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateSwitch.on = self.setAsPrivate.boolValue;
                    [self.privateSwitch addTarget:self action:@selector(privateSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.privateSwitch;
                }
                else if (indexPath.row == 1) {
                    if (self.markAsRead.boolValue) {
                        cell.textLabel.text = [NSString stringWithFormat:@"👏 %@", NSLocalizedString(@"Mark as read?", nil)];
                    }
                    else {
                        cell.textLabel.text = [NSString stringWithFormat:@"📦 %@", NSLocalizedString(@"Mark as read?", nil)];
                    }

                    self.readSwitch = [[UISwitch alloc] init];
                    CGSize size = cell.frame.size;
                    CGSize switchSize = self.readSwitch.frame.size;
                    self.readSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.readSwitch.on = self.markAsRead.boolValue;
                    [self.readSwitch addTarget:self action:@selector(readSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.readSwitch;
                }
                break;
            }

            default:
                break;
        }
    }

    return cell;
}

- (void)privateSwitchChanged:(id)sender {
    self.setAsPrivate = @(self.privateSwitch.on);
    [self.tableView reloadData];
}

- (void)readSwitchChanged:(id)sender {
    self.markAsRead = @(self.readSwitch.on);
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)close {
    [self.modalDelegate closeModal:self];
}

- (void)addBookmark {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
        #warning Should display a message to the user
        return;
    }

    if ([self.urlTextField.text isEqualToString:@""] || [self.titleTextField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil) message:NSLocalizedString(@"Add bookmark missing url or title", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        [mixpanel track:@"Failed to add bookmark" properties:@{@"Reason": @"Missing title or URL"}];
        return;
    }

    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&format=json&url=%@&description=%@&extended=%@&tags=%@&shared=%@&toread=%@", [[AppDelegate sharedDelegate] token], [self.urlTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.titleTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.descriptionTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.tagTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], self.privateSwitch.on ? @"no" : @"yes", self.readSwitch.on ? @"no" : @"yes"]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];

    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               AppDelegate *delegate = [AppDelegate sharedDelegate];

                               if (!error) {
                                   [self.modalDelegate closeModal:self];
                                   
                                   FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                   [db open];
                                   FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url = ?" withArgumentsInArray:@[self.urlTextField.text]];
                                   [results next];

                                   NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                       @"url": self.urlTextField.text,
                                       @"title": self.titleTextField.text,
                                       @"description": self.descriptionTextField.text,
                                       @"tags": self.tagTextField.text,
                                       @"unread": @(!self.readSwitch.on),
                                       @"private": @(self.privateSwitch.on)
                                   }];

                                   if ([results intForColumnIndex:0] > 0) {
                                       [mixpanel track:@"Updated bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                       [db executeUpdate:@"UPDATE bookmark SET title=:title, description=:description, tags=:tags, unread=:unread, private=:private WHERE url=:url" withParameterDictionary:params];
                                       delegate.bookmarksUpdatedMessage = NSLocalizedString(@"Bookmark Updated Message", nil);
                                   }
                                   else {
                                       params[@"created_at"] = [NSDate date];
                                       [mixpanel track:@"Added bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                       [db executeUpdate:@"INSERT INTO bookmark (title, description, url, private, unread, tags, created_at) VALUES (:title, :description, :url, :private, :unread, :tags, :created_at);" withParameterDictionary:params];
                                       delegate.bookmarksUpdatedMessage = NSLocalizedString(@"Bookmark Added Message", nil);
                                   }

                                   [db close];
                                   delegate.bookmarksUpdated = @(YES);
                               }
                               self.navigationItem.leftBarButtonItem.enabled = YES;
                               self.navigationItem.rightBarButtonItem.enabled = YES;
                               [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                               
    }];

}

@end

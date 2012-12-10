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

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.urlTextField = [[UITextField alloc] init];
        self.urlTextField.font = [UIFont systemFontOfSize:16];
        self.urlTextField.delegate = self;
        self.urlTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.urlTextField.placeholder = @"https://pinboard.in/";
        self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
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
        self.tagTextField.text = @"";
        
        self.markAsRead = @(NO);
        self.setAsPrivate = [[AppDelegate sharedDelegate] privateByDefault];
    }
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 4) {
        return 2;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return @"Separate tags with spaces";
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.accessoryView = nil;

    for (id view in cell.contentView.subviews) {
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
                self.tagTextField.frame = CGRectMake((frame.size.width - 300) / 2.0, (frame.size.height - 31) / 2.0, 300, 31);
                [cell.contentView addSubview:self.tagTextField];
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
                    break;
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
                    break;
                }
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
    [self.modalDelegate closeModal];
}

- (void)addBookmark {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
        #warning Should display a message to the user
        return;
    }

    if ([self.urlTextField.text isEqualToString:@""] || [self.titleTextField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted error", nil) message:NSLocalizedString(@"Add bookmark missing url or title", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        [mixpanel track:@"Failed to add bookmark" properties:@{@"Reason": @"Missing title or URL"}];
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&format=json&url=%@&description=%@&extended=%@&tags=%@&shared=%@&toread=%@", [[AppDelegate sharedDelegate] token], [self.urlTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.titleTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.descriptionTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.tagTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], self.privateSwitch.on ? @"no" : @"yes", self.readSwitch.on ? @"no" : @"yes"]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (!error) {
                                   [self.modalDelegate closeModal];
                                   
                                   UIAlertView *alert;
                                   
                                   FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
                                   [db open];
                                   FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url = ?" withArgumentsInArray:@[self.urlTextField.text]];
                                   [results next];
                                   
                                   // Bookmark already exists
                                   if ([results intForColumnIndex:0] > 0) {
                                       [mixpanel track:@"Updated bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                       alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Bookmark Updated Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                       
                                       NSDictionary *params = @{
                                           @"url": self.urlTextField.text,
                                           @"title": self.titleTextField.text,
                                           @"description": self.descriptionTextField.text,
                                           @"tags": self.tagTextField.text,
                                           @"unread": @(!self.readSwitch.on),
                                           @"private": @(self.privateSwitch.on),
                                       };
                                       
                                       [db executeUpdate:@"UPDATE bookmark SET title=:title description=:description tags=:tags unread=:unread private=:private WHERE url=:url" withParameterDictionary:params];
                                   }
                                   else {
                                       [mixpanel track:@"Added bookmark" properties:@{@"Private": @(self.privateSwitch.on), @"Read": @(self.readSwitch.on)}];
                                       alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Bookmark Added Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                   }
                                   [alert show];
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"BookmarkUpdated" object:nil];
                                   [db close];
                               }
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];

}

@end

//
//  AddBookmarkViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import "AddBookmarkViewController.h"
#import "NSString+URLEncoding.h"

@interface AddBookmarkViewController ()

@end

@implementation AddBookmarkViewController

@synthesize modalDelegate;
@synthesize urlTextField;
@synthesize descriptionTextField;
@synthesize titleTextField;
@synthesize tagTextField;
@synthesize privateSwitch;

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
    }
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"URL", nil);
            break;
        case 1:
            return NSLocalizedString(@"Title", nil);
            break;
        case 2:
            return NSLocalizedString(@"Description", nil);
            break;
        case 3:
            return NSLocalizedString(@"Tags", nil);
            break;
        case 4:
            return NSLocalizedString(@"Private", nil);
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
                cell.textLabel.text = NSLocalizedString(@"Set as private?", nil);
                CGSize size = cell.frame.size;
                self.privateSwitch = [[UISwitch alloc] init];
                CGSize switchSize = self.privateSwitch.frame.size;
                self.privateSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                [cell.contentView addSubview:self.privateSwitch];

                break;
            }
                
            default:
                break;
        }
    }

    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)close {
    [self.modalDelegate closeModal];
}

- (void)addBookmark {
    if (![[[AppDelegate sharedDelegate] connectionAvailable] boolValue]) {
        #warning Should display a message to the user
        return;
    }

    if ([self.urlTextField.text isEqualToString:@""] || [self.titleTextField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted error", nil) message:NSLocalizedString(@"Add bookmark missing url or title", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&format=json&url=%@&description=%@&extended=%@&tags=%@&shared=%@", [[AppDelegate sharedDelegate] token], [self.urlTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.titleTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.descriptionTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], [self.tagTextField.text urlEncodeUsingEncoding:NSUTF8StringEncoding], self.privateSwitch.on ? @"no" : @"yes"]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (!error) {
                                   [self.modalDelegate closeModal];
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Bookmark Added Message", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                                   [alert show];
                               }
                               [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];

}

@end

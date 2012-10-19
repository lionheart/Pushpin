//
//  AddBookmarkViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import "AddBookmarkViewController.h"

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

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    self.titleTextField.placeholder = @"Bookmarking for introverts";
    self.titleTextField.text = @"";
    
    self.tagTextField = [[UITextField alloc] init];
    self.tagTextField.font = [UIFont systemFontOfSize:16];
    self.tagTextField.delegate = self;
    self.tagTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.tagTextField.placeholder = @"bookmarking antisocial";
    self.tagTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tagTextField.text = @"";
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
            return @"URL";
            break;
        case 1:
            return @"Title";
            break;
        case 2:
            return @"Description";
            break;
        case 3:
            return @"Tags";
            break;
        case 4:
            return @"Private";
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
                cell.textLabel.text = @"Set as private?";
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
        // TODO
        return;
    }

    if ([self.urlTextField.text isEqualToString:@""] || [self.titleTextField.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh oh!" message:@"You can't add a bookmark without a URL or title." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }

    NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&format=json&url=%@&description=%@&extended=%@&tags=%@&shared=%@", [[AppDelegate sharedDelegate] token], self.urlTextField.text, self.titleTextField.text, self.descriptionTextField.text, self.tagTextField.text, self.privateSwitch.on ? @"no" : @"yes"] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSLog(@"%@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (!error) {
                                   [self.modalDelegate closeModal];
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your bookmark was added." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                   [alert show];
                               }
    }];

}

@end

//
//  SettingsViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "LoginViewController.h"


@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize logOutAlertView;
@synthesize browserActionSheet;
@synthesize supportActionSheet;
@synthesize readLaterServices;
@synthesize readLaterActionSheet;
@synthesize privateByDefaultSwitch;

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(showAboutPage)];
        
        self.logOutAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Log out warning title", nil) message:NSLocalizedString(@"Log out warning double check", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        self.browserActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Open links with:", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"Webview", @"Safari", @"Chrome", nil];
        self.supportActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Contact Support", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Request a feature", nil), NSLocalizedString(@"Report a bug", nil), NSLocalizedString(@"Email us", nil), nil];
        self.readLaterActionSheet = [[UIActionSheet alloc] initWithTitle:@"Set Read Later service to:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        self.readLaterServices = [NSMutableArray array];
        BOOL installed;
        
        installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"x-callback-instapaper://x-callback-url/add?google.com"]];
        if (installed) {
            [self.readLaterServices addObject:@[@(READLATER_INSTAPAPER)]];
            [self.readLaterActionSheet addButtonWithTitle:@"Instapaper"];
        }
        installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"readability://add/google.com/"]];
        if (installed) {
            [self.readLaterServices addObject:@[@(READLATER_READABILITY)]];
            [self.readLaterActionSheet addButtonWithTitle:@"Readability"];
        }

        readLaterActionSheet.cancelButtonIndex = [self.readLaterActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    }
    return self;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

- (void)showAboutPage {
    UIViewController *aboutViewController = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] init];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    webView.delegate = self;
    aboutViewController.view = webView;
    aboutViewController.title = NSLocalizedString(@"About Page Title", nil);
    aboutViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About Page Close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeAboutPage)];
    UINavigationController *aboutViewNavigationController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    aboutViewNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:aboutViewNavigationController animated:YES completion:nil];
}

- (void)closeAboutPage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)privateByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setPrivateByDefault:@(privateByDefaultSwitch.on)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (self.readLaterServices.count > 0) {
                return 3;
            }
            else {
                return 2;
            }

            break;
            
        case 1:
            return 2;
            break;
            
        default:
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *ChoiceCellIdentifier = @"ChoiceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        switch (indexPath.section) {
            case 0:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ChoiceCellIdentifier];
                break;
                
            case 1:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                break;
                
            default:
                break;
        }
    }
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Private by default?";
                    CGSize size = cell.frame.size;
                    self.privateByDefaultSwitch = [[UISwitch alloc] init];
                    CGSize switchSize = self.privateByDefaultSwitch.frame.size;
                    self.privateByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateByDefaultSwitch.on = [[AppDelegate sharedDelegate] privateByDefault].boolValue;
                    [self.privateByDefaultSwitch addTarget:self action:@selector(privateByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    [cell.contentView addSubview:self.privateByDefaultSwitch];
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Open links with:", nil);
                    switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
                        case BROWSER_WEBVIEW:
                            cell.detailTextLabel.text = @"Webview";
                            break;
                        case BROWSER_SAFARI:
                            cell.detailTextLabel.text = @"Safari";
                            break;
                        case BROWSER_CHROME:
                            cell.detailTextLabel.text = @"Chrome";
                            break;
                        default:
                            break;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
                case 2:
                    cell.textLabel.text = @"Read Later";
                    switch ([[[AppDelegate sharedDelegate] readlater] integerValue]) {
                        case READLATER_NONE:
                            cell.detailTextLabel.text = @"None";
                            break;
                        case READLATER_INSTAPAPER:
                            cell.detailTextLabel.text = @"Instapaper";
                            break;
                        case READLATER_READABILITY:
                            cell.detailTextLabel.text = @"Readability";
                            break;
                        default:
                            break;
                    }

                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                    break;
                default:
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Contact Support", nil);
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Log Out", nil);
                    break;
                default:
                    break;
            }

            break;
        }
        default:
            break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 1:
            return NSLocalizedString(@"Log out warning footer", nil);
            break;
            
        default:
            break;
    }
    return @"";
}

#pragma mark - Table view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.logOutAlertView) {
        if (buttonIndex == 1) {
            [[AppDelegate sharedDelegate] setToken:nil];
            [[AppDelegate sharedDelegate] setLastUpdated:nil];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:[AppDelegate databasePath] error:nil];
            LoginViewController *loginViewController = [[LoginViewController alloc] init];
            loginViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:loginViewController
                               animated:YES
                             completion:nil];

            [[AppDelegate sharedDelegate] migrateDatabase];
        }
    }
    else {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.com/app/chrome"]];
        }
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 3;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (row) {
        case 0:
            return NSLocalizedString(@"Default", nil);
            break;
        case 1:
            return @"Safari";
            break;
        case 2:
            return @"Chrome";
            break;
        default:
            break;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    BOOL installed;
    if (actionSheet == self.browserActionSheet) {
        switch (buttonIndex) {
            case 0:
                [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_WEBVIEW)];
                break;
                
            case 1:
                [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_SAFARI)];
                break;
                
            case 2: {
                installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://x1x"]];
                if (!installed) {
                    // Prompt user to install Chrome. If they say yes, set the browser and redirect them.
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Install Chrome Title", nil) message:NSLocalizedString(@"Install Chrome Description", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                    [alert show];
                }
                else {
                    [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_CHROME)];
                }
                break;
            }
                
            default:
                break;
        }
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (actionSheet == self.supportActionSheet) {
        if (buttonIndex == 3) {
            return;
        }
        
        if (buttonIndex == 2) {
            MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
            emailComposer.mailComposeDelegate = self;
            [emailComposer setSubject:NSLocalizedString(@"Support Email Subject", nil)];
            [emailComposer setToRecipients:@[@"support@aurora.io"]];
            [self presentViewController:emailComposer animated:YES completion:nil];
            return;
        }

        NSString *safariURL = @"http://aurora.io/support/pushpin";
        NSString *chromeURL = @"googlechrome://aurora.io/support/pushpin";
        NSURL *url;
        
        switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
            case BROWSER_WEBVIEW:
                url = [NSURL URLWithString:safariURL];
                break;
                
            case BROWSER_SAFARI:
                url = [NSURL URLWithString:safariURL];
                break;
                
            case BROWSER_CHROME:
                url = [NSURL URLWithString:chromeURL];
                break;
                
            default:
                break;
        }
        [[UIApplication sharedApplication] openURL:url];
    }
    else if (actionSheet == self.readLaterActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([buttonTitle isEqualToString:@"Instapaper"]) {
            [[AppDelegate sharedDelegate] setReadlater:@(READLATER_INSTAPAPER)];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
        else if ([buttonTitle isEqualToString:@"Readability"]) {
            [[AppDelegate sharedDelegate] setReadlater:@(READLATER_READABILITY)];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row == 1) {
                [self.browserActionSheet showFromTabBar:self.tabBarController.tabBar];
            }
            else if (indexPath.row == 2) {
                [self.readLaterActionSheet showFromTabBar:self.tabBarController.tabBar];
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    [self.supportActionSheet showFromTabBar:self.tabBarController.tabBar];
                    break;
                    
                case 1:
                    [self.logOutAlertView show];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                    
                default:
                    break;
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
}

@end

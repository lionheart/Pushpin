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

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"About"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(showAboutPage)];
        
        self.logOutAlertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"This will log you out and delete the local bookmark database from your device." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        self.browserActionSheet = [[UIActionSheet alloc] initWithTitle:@"Open links with:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Webview", @"Safari", @"Chrome", nil];
        self.supportActionSheet = [[UIActionSheet alloc] initWithTitle:@"Contact Support" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Request a feature", @"Report a bug", @"Email us", nil];
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
    aboutViewController.title = @"About";
    aboutViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeAboutPage)];
    UINavigationController *aboutViewNavigationController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    aboutViewNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:aboutViewNavigationController animated:YES completion:nil];
}

- (void)closeAboutPage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
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
            cell.textLabel.text = @"Open links with:";
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
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Contact Support";
                    break;
                case 1:
                    cell.textLabel.text = @"Log Out";
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
            return @"This will log you out of the application and will reset the application's bookmark database.";
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
            return @"Default";
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
    if (actionSheet == self.browserActionSheet) {
        switch (buttonIndex) {
            case 0:
                [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_WEBVIEW)];
                break;
                
            case 1:
                [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_SAFARI)];
                break;
                
            case 2: {
                BOOL installed = [[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString:@"googlechrome://x1x"]];
                if (!installed) {
                    // Prompt user to install Chrome. If they say yes, set the browser and redirect them.
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Install Chrome?" message:@"In order to open links with Google Chrome, you first have to install it. Click OK to continue." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
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
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
    else {
        if (buttonIndex == 3) {
            return;
        }
        
        if (buttonIndex == 2) {
            MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
            emailComposer.mailComposeDelegate = self;
            [emailComposer setSubject:@"Help me!"];
            [emailComposer setToRecipients:@[@"support@pinboardforiphone.com"]];
            [self presentViewController:emailComposer animated:YES completion:nil];
            return;
        }

        NSString *safariURL = @"https://trello.com/board/thumbtack-for-pinboard/50ad16761b7a9d3904006e15";
        NSString *chromeURL = @"googlechromes://trello.com/board/thumbtack-for-pinboard/50ad16761b7a9d3904006e15";
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            [self.browserActionSheet showFromTabBar:self.tabBarController.tabBar];
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

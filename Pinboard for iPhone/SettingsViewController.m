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

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"About"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(showAboutPage)];
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
    return 1;
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
            /* CGSize size = cell.frame.size;
            UISwitch *switchView = [[UISwitch alloc] init];
            CGSize switchSize = switchView.frame.size;
            switchView.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
            [cell.contentView addSubview:switchView]; */
            cell.textLabel.text = @"Open links with:";
            cell.detailTextLabel.text = @"Safari";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case 1:
            cell.textLabel.text = @"Log Out";
            break;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {

            float screenWidth = [UIScreen mainScreen].bounds.size.width;
            CGRect pickerFrame = CGRectMake(0, 0, screenWidth, 0);
            UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
            UIViewController *viewController = [[UIViewController alloc] init];
            viewController.view = pickerView;
            viewController.view.frame = pickerFrame;
            pickerView.showsSelectionIndicator = YES;
            pickerView.dataSource = self;
            pickerView.delegate = self;
            [self presentViewController:viewController animated:YES completion:nil];
            break;
        }
        case 1: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"This will log you out and delete the local bookmark database from your device." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            [alert show];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
            
        default:
            break;
    }
}

@end

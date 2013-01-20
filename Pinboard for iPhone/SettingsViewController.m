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
#import "UserVoice.h"
#import "UVStyleSheet.h"
#import "ASStyleSheet.h"
#import "PocketAPI.h"
#import "NSString+URLEncoding.h"
#import "Lockbox.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize logOutAlertView;
@synthesize browserActionSheet;
@synthesize supportActionSheet;
@synthesize readLaterServices;
@synthesize readLaterActionSheet;
@synthesize privateByDefaultSwitch;
@synthesize instapaperAlertView;
@synthesize installChromeAlertView;
@synthesize installiCabMobileAlertView;
@synthesize instapaperVerificationAlertView;
@synthesize loadingIndicator;
@synthesize readByDefaultSwitch;

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About Navigation Bar", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(showAboutPage)];
        
        self.logOutAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Log out warning title", nil) message:NSLocalizedString(@"Log out warning double check", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        self.browserActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Open links with:", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"Webview", @"Safari", @"Chrome", @"iCab Mobile", nil];
        self.supportActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Contact Support", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Request a feature", nil), NSLocalizedString(@"Report a bug", nil), @"Tweet us", NSLocalizedString(@"Email us", nil), nil];
        self.readLaterActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Set Read Later service to:", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        self.readLaterServices = [NSMutableArray array];
        BOOL installed;
        
        [self.readLaterServices addObject:@[@(READLATER_INSTAPAPER)]];
        [self.readLaterActionSheet addButtonWithTitle:@"Instapaper"];

        installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"readability://add/google.com/"]];
        if (installed) {
            [self.readLaterServices addObject:@[@(READLATER_READABILITY)]];
            [self.readLaterActionSheet addButtonWithTitle:@"Readability"];
        }

        [self.readLaterServices addObject:@[@(READLATER_POCKET)]];
        [self.readLaterActionSheet addButtonWithTitle:@"Pocket"];
        [self.readLaterActionSheet addButtonWithTitle:@"None"];

        self.readLaterActionSheet.cancelButtonIndex = [self.readLaterActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

        self.instapaperAlertView = [[UIAlertView alloc] initWithTitle:@"Instapaper Login" message:@"Password may be blank." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Submit", nil];
        self.instapaperAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [[self.instapaperAlertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
        [[self.instapaperAlertView textFieldAtIndex:0] setReturnKeyType:UIReturnKeyNext];
        [[self.instapaperAlertView textFieldAtIndex:0] setPlaceholder:@"Email Address"];
        [[self.instapaperAlertView textFieldAtIndex:1] setKeyboardType:UIKeyboardTypeAlphabet];
        [[self.instapaperAlertView textFieldAtIndex:1] setReturnKeyType:UIReturnKeyGo];
        [[self.instapaperAlertView textFieldAtIndex:1] setDelegate:self];

        self.installChromeAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Install Chrome Title", nil) message:NSLocalizedString(@"Install Chrome Description", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Install", nil), nil];
        self.installiCabMobileAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Install iCab Mobile?", nil) message:NSLocalizedString(@"In order to open links with iCab Mobile, you first have to install it. Click OK to continue.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Install", nil), nil];
        self.instapaperVerificationAlertView = [[UIAlertView alloc] initWithTitle:@"Verifying credentials"
                                                                          message:@"Logging into Instapaper"
                                                                         delegate:nil
                                                                cancelButtonTitle:nil
                                                                otherButtonTitles:nil];
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == [self.instapaperAlertView textFieldAtIndex:1]) {
        [self.instapaperAlertView dismissWithClickedButtonIndex:0 animated:YES];
    }
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Mixpanel sharedInstance] track:@"Opened settings"];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

- (void)showAboutPage {
    [[Mixpanel sharedInstance] track:@"Opened about page"];
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
    [[AppDelegate sharedDelegate] setPrivateByDefault:@(self.privateByDefaultSwitch.on)];
}

- (void)readByDefaultSwitchChangedValue:(id)sender {
    [[AppDelegate sharedDelegate] setReadByDefault:@(self.readByDefaultSwitch.on)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (self.readLaterServices.count > 0) {
                return 4;
            }
            else {
                return 3;
            }

            break;
            
        case 1:
            return 3;
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
    
    cell.accessoryView = nil;
    
    CGSize size;
    CGSize switchSize;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Private by default?", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.privateByDefaultSwitch = [[UISwitch alloc] init];
                    switchSize = self.privateByDefaultSwitch.frame.size;
                    self.privateByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.privateByDefaultSwitch.on = [[AppDelegate sharedDelegate] privateByDefault].boolValue;
                    [self.privateByDefaultSwitch addTarget:self action:@selector(privateByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.privateByDefaultSwitch;
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Read by default?", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    size = cell.frame.size;
                    self.readByDefaultSwitch = [[UISwitch alloc] init];
                    switchSize = self.readByDefaultSwitch.frame.size;
                    self.readByDefaultSwitch.frame = CGRectMake(size.width - switchSize.width - 30, (size.height - switchSize.height) / 2.0, switchSize.width, switchSize.height);
                    self.readByDefaultSwitch.on = [[AppDelegate sharedDelegate] readByDefault].boolValue;
                    [self.readByDefaultSwitch addTarget:self action:@selector(readByDefaultSwitchChangedValue:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.readByDefaultSwitch;
                    break;

                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Open links with:", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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
                    
                case 3:
                    cell.textLabel.text = NSLocalizedString(@"Read Later", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    switch ([[[AppDelegate sharedDelegate] readlater] integerValue]) {
                        case READLATER_NONE:
                            cell.detailTextLabel.text = NSLocalizedString(@"None", nil);
                            break;
                        case READLATER_INSTAPAPER:
                            cell.detailTextLabel.text = @"Instapaper";
                            break;
                        case READLATER_READABILITY:
                            cell.detailTextLabel.text = @"Readability";
                            break;
                        case READLATER_POCKET:
                            cell.detailTextLabel.text = @"Pocket";
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
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Give Feedback", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Log Out", nil);
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
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
    else if (alertView == self.instapaperAlertView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.instapaperVerificationAlertView show];

            if (self.instapaperVerificationAlertView != nil) {
                self.loadingIndicator.center = CGPointMake(self.instapaperVerificationAlertView.bounds.size.width/2, self.instapaperVerificationAlertView.bounds.size.height-45);
                [self.loadingIndicator startAnimating];
                [self.instapaperVerificationAlertView addSubview:self.loadingIndicator];
            }
        });

        NSString *username = [[alertView textFieldAtIndex:0] text];
        NSString *password = [[alertView textFieldAtIndex:1] text];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/authenticate?username=%@&password=%@", [username urlEncodeUsingEncoding:NSUTF8StringEncoding], [password urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];

        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   [self.instapaperVerificationAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                   if (httpResponse.statusCode == 200) {
                                       [Lockbox setString:username forKey:@"InstapaperUsername"];
                                       [Lockbox setString:password forKey:@"InstapaperPassword"];
                                       [[AppDelegate sharedDelegate] setReadlater:@(READLATER_INSTAPAPER)];
                                       [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Instapaper"];
                                       [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil)
                                                                                       message:@"You've successfully logged in."
                                                                                      delegate:nil
                                                                             cancelButtonTitle:nil
                                                                             otherButtonTitles:nil];
                                       [alert show];
                                       int64_t delayInSeconds = 2.0;
                                       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                           [alert dismissWithClickedButtonIndex:0 animated:YES];
                                       });
                                   }
                                   else {
                                       [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Error", nil)
                                                                  message:@"We couldn't log you into Instapaper with those credentials."
                                                                 delegate:nil
                                                        cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"Lighthearted Disappointment", nil), nil] show];
                                   }
                               }];
    }
    else if (alertView == self.installChromeAlertView && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.com/app/chrome"]];
    }
    else if (alertView == self.installiCabMobileAlertView && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/app/icab-mobile-web-browser/id308111628"]];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    BOOL installed;
    if (actionSheet == self.browserActionSheet) {
        switch (buttonIndex) {
            case 0:
                [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_WEBVIEW)];
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Webview"];
                break;
                
            case 1:
                [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_SAFARI)];
                [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Safari"];
                break;
                
            case 2: {
                installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://google.com/"]];
                if (!installed) {
                    [self.installChromeAlertView show];
                }
                else {
                    [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_CHROME)];
                    [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"Chrome"];
                }
                break;
            }
                
            case 3: {
                installed = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"icabmobile://google.com/"]];
                if (!installed) {
                    [self.installiCabMobileAlertView show];
                }
                else {
                    [[AppDelegate sharedDelegate] setBrowser:@(BROWSER_ICAB_MOBILE)];
                    [[[Mixpanel sharedInstance] people] set:@"Browser" to:@"iCab Mobile"];
                }
                break;
            }

            default:
                break;
        }
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (actionSheet == self.supportActionSheet) {
        if (buttonIndex == 3) {
            MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
            emailComposer.mailComposeDelegate = self;
            [emailComposer setSubject:NSLocalizedString(@"Support Email Subject", nil)];
            [emailComposer setToRecipients:@[@"support@aurora.io"]];
            [self presentViewController:emailComposer animated:YES completion:nil];
            return;
        }
        else if (buttonIndex == 0) {
            UVConfig *config = [UVConfig configWithSite:@"aurorasoftware.uservoice.com"
                                                 andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                              andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
            
            [UserVoice presentUserVoiceInterfaceForParentViewController:self andConfig:config];
            return;
        }
    }
    else if (actionSheet == self.readLaterActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

        if ([buttonTitle isEqualToString:@"Instapaper"]) {
            [self.instapaperAlertView show];
        }
        else if ([buttonTitle isEqualToString:@"Readability"]) {
            [[AppDelegate sharedDelegate] setReadlater:@(READLATER_READABILITY)];
            [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Readability"];
        }
        else if ([buttonTitle isEqualToString:@"Pocket"]) {
            [[PocketAPI sharedAPI] loginWithHandler:^(PocketAPI *API, NSError *error) {
                if (!error && API.loggedIn) {
                    [[AppDelegate sharedDelegate] setReadlater:@(READLATER_POCKET)];
                    [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"Pocket"];
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                }
            }];
        }
        else if ([buttonTitle isEqualToString:@"None"]) {
            [[AppDelegate sharedDelegate] setReadlater:nil];
            [[[Mixpanel sharedInstance] people] set:@"Read Later Service" to:@"None"];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }

    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row == 2) {
                [self.browserActionSheet showFromTabBar:self.tabBarController.tabBar];
            }
            else if (indexPath.row == 3) {
                [self.readLaterActionSheet showFromTabBar:self.tabBarController.tabBar];
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    UVConfig *config = [UVConfig configWithSite:@"aurorasoftware.uservoice.com"
                                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
                    [UVStyleSheet setStyleSheet:[[ASStyleSheet alloc] init]];
                    [UserVoice presentUserVoiceContactUsFormForParentViewController:self andConfig:config];
                    break;
                }
                    
                case 1: {
                    UVConfig *config = [UVConfig configWithSite:@"aurorasoftware.uservoice.com"
                                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
                    [UVStyleSheet setStyleSheet:[[ASStyleSheet alloc] init]];
                    [UserVoice presentUserVoiceForumForParentViewController:self andConfig:config];
                    break;
                }
                    
                case 2:
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

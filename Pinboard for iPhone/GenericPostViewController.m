//
//  GenericPostViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/1/13.
//
//

#import "GenericPostViewController.h"
#import "BookmarkCell.h"
#import "NSAttributedString+Attributes.h"
#import "NSString+URLEncoding2.h"
#import "RDActionSheet.h"
#import <QuartzCore/QuartzCore.h>
#import "OAuthConsumer.h"
#import "KeychainItemWrapper.h"
#import "PocketAPI.h"
#import "ASPinboard/ASPinboard.h"
#import "PPCoreGraphics.h"
#import "TSMiniWebBrowser.h"

@interface GenericPostViewController ()

@end

@implementation GenericPostViewController

@synthesize postDataSource;
@synthesize processingPosts;
@synthesize selectedPost;
@synthesize longPressGestureRecognizer;
@synthesize selectedIndexPath;
@synthesize actionSheetVisible;
@synthesize confirmDeletionAlertView;
@synthesize pullToRefreshView;
@synthesize pullToRefreshImageView;
@synthesize loading;

- (void)checkForBookmarkUpdates {
    if (!self.bookmarkRefreshTimerPaused) {
        self.bookmarkRefreshTimerPaused = YES;
        AppDelegate *delegate = [AppDelegate sharedDelegate];
        if (delegate.bookmarksUpdated.boolValue) {
            [self updateFromLocalDatabase];
            delegate.bookmarksUpdated = @NO;
        }
    }
}

- (void)viewDidLoad {
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
    
    self.loading = NO;
    self.pullToRefreshView = [[UIView alloc] initWithFrame:CGRectMake(0, -30, 320, 30)];
    self.pullToRefreshView.backgroundColor = [UIColor whiteColor];
    self.pullToRefreshImageView = [[PPLoadingView alloc] init];
    [self.pullToRefreshView addSubview:self.pullToRefreshImageView];
    [self.tableView addSubview:self.pullToRefreshView];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.tableView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.leftBarButtonItem.title = @"";
    
    if ([self.postDataSource numberOfPosts] == 0) {
        self.tableView.separatorColor = [UIColor clearColor];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.processingPosts = NO;
    self.actionSheetVisible = NO;

    self.bookmarkRefreshTimerPaused = NO;
    self.bookmarkRefreshTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(checkForBookmarkUpdates) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.bookmarkRefreshTimer forMode:NSDefaultRunLoopMode];

    if ([self.postDataSource numberOfPosts] == 0) {
        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
        
        self.loading = YES;

        [self.pullToRefreshImageView startAnimating];
        self.pullToRefreshImageView.frame = CGRectMake(140, 10, 40, 40);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateFromLocalDatabase];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.bookmarkRefreshTimerPaused = YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    NSString *urlString = [self.postDataSource urlForPostAtIndex:indexPath.row];
    
    switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
        NSRange httpRange = NSMakeRange(NSNotFound, 0);
        if ([urlString hasPrefix:@"http"]) {
            httpRange = [urlString rangeOfString:@"http"];
        }

        case BROWSER_WEBVIEW: {
            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Webview"}];
            TSMiniWebBrowser *webBrowser = [[TSMiniWebBrowser alloc] initWithUrl:[NSURL URLWithString:urlString]];
            [self.navigationController pushViewController:webBrowser animated:YES];
            break;
        }
            
        case BROWSER_SAFARI: {
            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Safari"}];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
            break;
        }
            
        case BROWSER_CHROME:
            if (httpRange.location != NSNotFound) {
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=pushpin%%3A%%2F%%2F&&x-source=Pushpin", [urlString urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                    [[UIApplication sharedApplication] openURL:url];
                }
                else {
                    NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"googlechrome"]];
                    [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"Google Chrome failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
            }
            
            break;
            
        case BROWSER_ICAB_MOBILE:
            if (httpRange.location != NSNotFound) {
                NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"icabmobile"]];
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"iCab Mobile"}];
                [[UIApplication sharedApplication] openURL:url];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"iCab Mobile failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
            }
            
            break;
            
        case BROWSER_OPERA:
            if (httpRange.location != NSNotFound) {
                NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"ohttp"]];
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Opera"}];
                [[UIApplication sharedApplication] openURL:url];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"Opera failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
            }
            
            break;
            
        case BROWSER_DOLPHIN:
            if (httpRange.location != NSNotFound) {
                NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"dolphin"]];
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"dolphin"}];
                [[UIApplication sharedApplication] openURL:url];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"iCab Mobile failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
            }
            
            break;
            
        case BROWSER_CYBERSPACE:
            if (httpRange.location != NSNotFound) {
                NSURL *url = [NSURL URLWithString:[urlString stringByReplacingCharactersInRange:httpRange withString:@"cyber"]];
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Cyberspace Browser"}];
                [[UIApplication sharedApplication] openURL:url];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"Cyberspace failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
            }
            
            break;
            
        default:
            break;
    }
}

- (void)longPressGestureDetected:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint pressPoint;
        pressPoint = [recognizer locationInView:self.tableView];
        self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:pressPoint];
        self.selectedPost = [self.postDataSource postAtIndex:self.selectedIndexPath.row];
        [self openActionSheetForSelectedPost];
    }
}

- (void)updateFromLocalDatabase {
    self.processingPosts = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.postDataSource updatePostsFromDatabaseWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.processingPosts = NO;
                    
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationTop];
                    [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationBottom];
                    [self.tableView endUpdates];
                    self.tableView.separatorColor = HEX(0xE0E0E0ff);
                    
                    if (self.loading) {
                        self.loading = NO;
                        [UIView animateWithDuration:0.2 animations:^{
                            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                        } completion:^(BOOL finished) {
                            [self.pullToRefreshImageView stopAnimating];
                        }];
                    }
                    
                    self.bookmarkRefreshTimerPaused = NO;
                });
            });
        } failure:nil];
    });
}

- (void)update {
    self.processingPosts = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.postDataSource updatePostsWithSuccess:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.processingPosts = NO;
                
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationBottom];
                [self.tableView endUpdates];
                self.tableView.separatorColor = HEX(0xE0E0E0ff);

                if (self.loading) {
                    self.loading = NO;
                    [UIView animateWithDuration:0.2 animations:^{
                        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                    } completion:^(BOOL finished) {
                        [self.pullToRefreshImageView stopAnimating];
                    }];
                }
            });
        } failure:nil];
    });
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.processingPosts) {
        if ([self.postDataSource respondsToSelector:@selector(willDisplayIndexPath:callback:)]) {
            [self.postDataSource willDisplayIndexPath:indexPath callback:^(BOOL needsUpdate) {
                if (needsUpdate) {
                    [self update];
                }
            }];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.postDataSource numberOfPosts];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAttributedString *string = [self.postDataSource attributedStringForPostAtIndex:indexPath.row];
    return [string sizeConstrainedToSize:CGSizeMake(300, CGFLOAT_MAX)].height + 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.contentView.backgroundColor = [UIColor clearColor];
    }

    NSAttributedString *string;

    string = [self.postDataSource attributedStringForPostAtIndex:indexPath.row];

    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    [cell.textView setText:string];
    
    for (NSDictionary *link in [self.postDataSource linksForPostAtIndex:indexPath.row]) {
        [cell.textView addLinkToURL:link[@"url"] withRange:NSMakeRange([link[@"location"] integerValue], [link[@"length"] integerValue])];
    }
    
    for (id subview in [cell.contentView subviews]) {
        if (![subview isKindOfClass:[TTTAttributedLabel class]]) {
            [subview removeFromSuperview];
        }
    }

    NSArray* sublayers = [NSArray arrayWithArray:cell.contentView.layer.sublayers];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            [layer removeFromSuperlayer];
        }
    }

    CGFloat height = [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:indexPath];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, 320.f, height);
    gradient.colors = @[(id)[HEX(0xFAFBFEff) CGColor], (id)[HEX(0xF2F6F9ff) CGColor]];
    gradient.name = @"Gradient";
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, height)];
    cell.backgroundView = backgroundView;
    [cell.backgroundView.layer addSublayer:gradient];

    CAGradientLayer *selectedGradient = [CAGradientLayer layer];
    selectedGradient.frame = CGRectMake(0, 0, 320.f, height);
    selectedGradient.colors = @[(id)[HEX(0xE1E4ECff) CGColor], (id)[HEX(0xF3F5F9ff) CGColor]];
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, height)];
    cell.selectedBackgroundView = selectedBackgroundView;
    [cell.selectedBackgroundView.layer addSublayer:selectedGradient];

    BOOL isPrivate = [self.postDataSource isPostAtIndexPrivate:indexPath.row];
    if (isPrivate) {
        UIImageView *lockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top-right-lock"]];
        lockImageView.frame = CGRectMake(302.f, 0, 18.f, 19.f);
        [cell.contentView addSubview:lockImageView];
    }
    
    BOOL isStarred = [self.postDataSource isPostAtIndexStarred:indexPath.row];
    if (isStarred) {
        UIImageView *starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top-left-star"]];
        starImageView.frame = CGRectMake(0, 0, 18.f, 19.f);
        [cell.contentView addSubview:starImageView];
    }

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    return cell;
}

- (void)openActionSheetForSelectedPost {
    if (!self.actionSheetVisible) {
        NSString *urlString;
        if ([self.selectedPost[@"url"] length] > 67) {
            urlString = [NSString stringWithFormat:@"%@...", [self.selectedPost[@"url"] substringToIndex:67]];
        }
        else {
            urlString = self.selectedPost[@"url"];
        }
        RDActionSheet *sheet = [[RDActionSheet alloc] initWithTitle:urlString delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

        PPPostAction action;
        for (id PPPAction in [self.postDataSource actionsForPost:self.selectedPost]) {
            action = [PPPAction integerValue];
            if (action == PPPostActionCopyToMine) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Copy to mine", nil)];
            }
            else if (action == PPPostActionCopyURL) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
            }
            else if (action == PPPostActionDelete) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Delete Bookmark", nil)];
            }
            else if (action == PPPostActionEdit) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Edit Bookmark", nil)];
            }
            else if (action == PPPostActionMarkAsRead) {
                [sheet addButtonWithTitle:NSLocalizedString(@"Mark as read", nil)];
            }
            else if (action == PPPostActionReadLater) {
                NSInteger readlater = [[[AppDelegate sharedDelegate] readlater] integerValue];
                if (readlater == READLATER_INSTAPAPER) {
                    [sheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
                }
                else if (readlater == READLATER_READABILITY) {
                    [sheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
                }
                else if (readlater == READLATER_POCKET) {
                    [sheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
                }
            }
        }
        
        [sheet showFrom:self.navigationController.view];
        self.tableView.scrollEnabled = NO;
        self.actionSheetVisible = YES;
    }
}

#pragma mark - Table view delegate

- (void)closeModal:(UIViewController *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - RDActionSheet

- (void)actionSheet:(RDActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    self.tableView.scrollEnabled = YES;
    self.actionSheetVisible = NO;
    
    if ([title isEqualToString:NSLocalizedString(@"Delete Bookmark", nil)]) {
        [self showConfirmDeletionAlert];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Edit Bookmark", nil)]) {
        UIViewController *vc = [self.postDataSource editViewControllerForPostAtIndex:self.selectedIndexPath.row withDelegate:self];
        [self presentViewController:vc animated:YES completion:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Mark as read", nil)]) {
        [self markPostAsRead];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Instapaper", nil)]) {
        [self sendToReadLater];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Readability", nil)]) {
        [self sendToReadLater];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Pocket", nil)]) {
        [self sendToReadLater];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Copy URL", nil)]) {
        [self copyURL];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Copy to mine", nil)]) {
        UIViewController *vc = [self.postDataSource addViewControllerForPostAtIndex:self.selectedIndexPath.row delegate:self];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Post Action Methods

- (void)markPostAsRead {
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    if (![[delegate connectionAvailable] boolValue]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"Connection unavailable.";
        notification.userInfo = @{@"success": @NO, @"updated": @YES};
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    else {
        [self.postDataSource markPostAsRead:self.selectedPost[@"url"] callback:^(NSError *error) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            if (error == nil) {
                notification.alertBody = NSLocalizedString(@"Bookmark Updated Message", nil);
                notification.userInfo = @{@"success": @YES, @"updated": @YES};
                [self updateFromLocalDatabase];
            }
            else {
                notification.userInfo = @{@"success": @NO, @"updated": @NO};
                if (error.code == PinboardErrorBookmarkNotFound) {
                    notification.alertBody = @"Error marking as read.";
                }
                else {
                    notification.alertBody = NSLocalizedString(@"Bookmark Update Error Message", nil);
                }
            }
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }];
    }
}

- (void)copyURL {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [[UIPasteboard generalPasteboard] setString:self.selectedPost[@"url"]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)sendToReadLater {
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    NSString *urlString = self.selectedPost[@"url"];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstapaperOAuth" accessGroup:nil];
        NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
        NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1/bookmarks/add"]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
        OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        NSMutableArray *parameters = [[NSMutableArray alloc] init];
        [parameters addObject:[OARequestParameter requestParameter:@"url" value:urlString]];
        [parameters addObject:[OARequestParameter requestParameter:@"description" value:@"Sent from Pushpin"]];
        [request setParameters:parameters];
        [request prepare];
        
        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   
                                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                                   notification.alertAction = @"Open Pushpin";
                                   if (httpResponse.statusCode == 200) {
                                       notification.alertBody = NSLocalizedString(@"Sent to Instapaper.", nil);
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                   }
                                   else if (httpResponse.statusCode == 1221) {
                                       notification.alertBody = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                       
                                       if (httpResponse.statusCode == 403) {
                                           [[AppDelegate sharedDelegate] setReadlater:@(READLATER_NONE)];
                                       }
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_READABILITY) {
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
        NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
        NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
        NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.readability.com/api/rest/v1/bookmarks"]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
        OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"POST"];
        [request setParameters:@[[OARequestParameter requestParameter:@"url" value:urlString]]];
        [request prepare];
        
        [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                                   UILocalNotification *notification = [[UILocalNotification alloc] init];
                                   notification.alertAction = @"Open Pushpin";
                                   
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   if (httpResponse.statusCode == 202) {
                                       notification.alertBody = @"Sent to Readability.";
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                   }
                                   else if (httpResponse.statusCode == 409) {
                                       notification.alertBody = @"Link already sent to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                   }
                                   else {
                                       notification.alertBody = @"Error sending to Readability.";
                                       notification.userInfo = @{@"success": @NO, @"updated": @NO};
                                       
                                       if (httpResponse.statusCode == 403) {
                                           [[AppDelegate sharedDelegate] setReadlater:@(READLATER_NONE)];
                                       }
                                   }
                                   [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                               }];
    }
    else if (readLater.integerValue == READLATER_POCKET) {
        [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:urlString]
                             withTitle:self.selectedPost[@"title"]
                               handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                   if (!error) {
                                       UILocalNotification *notification = [[UILocalNotification alloc] init];
                                       notification.alertBody = @"Sent to Pocket.";
                                       notification.userInfo = @{@"success": @YES, @"updated": @NO};
                                       [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                       
                                       [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                   }
                               }];
    }
}

- (void)showConfirmDeletionAlert {
    self.confirmDeletionAlertView = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil) message:NSLocalizedString(@"Delete Bookmark Warning", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];

    [self.confirmDeletionAlertView show];
}

#pragma mark - Alert View Delegate

- (void)alertView:(WCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.confirmDeletionAlertView) {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:NSLocalizedString(@"Yes", nil)]) {
            [self.postDataSource deletePosts:@[self.selectedPost] callback:^(NSIndexPath *indexPath) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];
                    });
                });
            }];
        }
    }
}

#pragma mark - Scroll View delegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.loading) {
        CGFloat offset = scrollView.contentOffset.y;
        if (offset < -60) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.5 animations:^{
                        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
                        self.loading = YES;
                        [self.pullToRefreshImageView startAnimating];
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.5 animations:^{
                            self.pullToRefreshImageView.frame = CGRectMake(140, 10, 40, 40);
                            
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                [self update];
                            });
                        }];
                    }];
                });
            });
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.loading) {
        CGFloat offset = scrollView.contentOffset.y;
        NSInteger index = MAX(1, 32 - MIN((-offset / 80.) * 32, 32));
        NSString *imageName = [NSString stringWithFormat:@"ptr_%02d", index];
        UIOffset imageOffset;
        if (offset > -60) {
            imageOffset = UIOffsetMake(0, -(50 + offset));
        }
        else {
            imageOffset = UIOffsetMake(0, 10);
        }
        
        self.pullToRefreshView.frame = CGRectMake(0, offset, 320, -offset);
        self.pullToRefreshImageView.image = [UIImage imageNamed:imageName];
        self.pullToRefreshImageView.frame = CGRectMake(140, imageOffset.vertical, 40, 40);
    }
}

@end

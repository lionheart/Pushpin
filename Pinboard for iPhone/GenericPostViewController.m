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
#import "RDActionSheet.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "OAuthConsumer.h"
#import "KeychainItemWrapper.h"
#import "PocketAPI.h"
#import "ASPinboard/ASPinboard.h"

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
@synthesize timerPaused;

- (void)checkForPostUpdates {
    if (!timerPaused) {
        AppDelegate *delegate = [AppDelegate sharedDelegate];
        if (delegate.bookmarksUpdated.boolValue) {
            [self update];
            delegate.bookmarksUpdated = @NO;
        }
    }
}

- (void)viewDidLoad {
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureDetected:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.timerPaused = NO;
    self.processingPosts = NO;
    self.actionSheetVisible = NO;
    
    self.updateTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(checkForPostUpdates) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.updateTimer forMode:NSDefaultRunLoopMode];

    [self update];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.timerPaused = YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
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

- (void)update {
    self.timerPaused = YES;
    self.processingPosts = YES;
    [self.postDataSource updatePosts:^(NSArray *indexPathsToAdd, NSArray *indexPathsToReload, NSArray *indexPathsToRemove) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.processingPosts = NO;
                self.timerPaused = NO;
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView deleteRowsAtIndexPaths:indexPathsToRemove withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            });
        });
    }];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.processingPosts) {
        [self.postDataSource willDisplayIndexPath:indexPath callback:^(BOOL needsUpdate) {
            if (needsUpdate) {
                [self update];
            }
        }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.postDataSource numberOfPosts];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Book" size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:@"Avenir-Medium" size:12.f];
    
    CGFloat height = 20.0f;
    NSString *title = [self.postDataSource titleForPostAtIndex:indexPath.row];
    NSString *description = [self.postDataSource descriptionForPostAtIndex:indexPath.row];
    NSString *tags = [self.postDataSource tagsForPostAtIndex:indexPath.row];

    height += ceilf([title sizeWithFont:titleFont constrainedToSize:CGSizeMake(320.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    
    if (![description isEqualToString:@""]) {
        height += ceilf([description sizeWithFont:descriptionFont constrainedToSize:CGSizeMake(320.f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    
    if (![tags isEqualToString:@""]) {
        height += ceilf([tags sizeWithFont:tagsFont constrainedToSize:CGSizeMake(320.f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }

    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.contentView.backgroundColor = [UIColor clearColor];
    }

    NSAttributedString *string;

    string = [self attributedStringForPostAtIndexPath:indexPath];

    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    [cell.textView setText:string];
    
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
        [sheet addButtonWithTitle:NSLocalizedString(@"Delete Bookmark", nil)];
        [sheet addButtonWithTitle:NSLocalizedString(@"Edit Bookmark", nil)];
        
        if ([self.selectedPost[@"unread"] boolValue]) {
            [sheet addButtonWithTitle:NSLocalizedString(@"Mark as read", nil)];
        }

        [sheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];

        NSNumber *readlater = [[AppDelegate sharedDelegate] readlater];
        if (readlater.integerValue == READLATER_INSTAPAPER) {
            [sheet addButtonWithTitle:NSLocalizedString(@"Send to Instapaper", nil)];
        }
        else if (readlater.integerValue == READLATER_READABILITY) {
            [sheet addButtonWithTitle:NSLocalizedString(@"Send to Readability", nil)];
        }
        else if (readlater.integerValue == READLATER_POCKET) {
            [sheet addButtonWithTitle:NSLocalizedString(@"Send to Pocket", nil)];
        }
        
        [sheet showFrom:self.view];
        self.tableView.scrollEnabled = NO;
        self.actionSheetVisible = YES;
    }
}

#pragma mark - Table view delegate

- (NSMutableAttributedString *)attributedStringForPostAtIndexPath:(NSIndexPath *)indexPath {
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Book" size:14.f];
    UIFont *tagsFont = [UIFont fontWithName:@"Avenir-Medium" size:12.f];

    NSString *title = [self.postDataSource titleForPostAtIndex:indexPath.row];
    NSString *description = [self.postDataSource descriptionForPostAtIndex:indexPath.row];
    NSString *tags = [self.postDataSource tagsForPostAtIndex:indexPath.row];
    BOOL isRead = [self.postDataSource isPostAtIndexRead:indexPath.row];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = [self.postDataSource rangeForTitleForPostAtIndex:indexPath.row];

    NSRange descriptionRange = [self.postDataSource rangeForDescriptionForPostAtIndex:indexPath.row];
    if (descriptionRange.location != NSNotFound) {
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }
    
    NSRange tagRange = [self.postDataSource rangeForTagsForPostAtIndex:indexPath.row];
    BOOL hasTags = tagRange.location != NSNotFound;
    if (hasTags) {
        [content appendString:[NSString stringWithFormat:@"\n%@", tags]];
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:titleFont range:titleRange];
    [attributedString setFont:descriptionFont range:descriptionRange];
    [attributedString setTextColor:HEX(0x33353Bff)];
    
    if (isRead) {
        [attributedString setTextColor:HEX(0x96989Dff) range:titleRange];
        [attributedString setTextColor:HEX(0x96989Dff) range:descriptionRange];
    }
    else {
        [attributedString setTextColor:HEX(0x353840ff) range:titleRange];
        [attributedString setTextColor:HEX(0x696F78ff) range:descriptionRange];
    }

    if (hasTags) {
        [attributedString setTextColor:HEX(0xA5A9B2ff) range:tagRange];
        [attributedString setFont:tagsFont range:tagRange];
    }
    
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    return attributedString;
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
        // [[AppDelegate sharedDelegate] showAddBookmarkViewControllerWithBookmark:self.bookmark update:@(YES) callback:nil];
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
            self.timerPaused = YES;
            [self.postDataSource deletePosts:@[self.selectedPost] callback:^(NSIndexPath *indexPath) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                        [self.tableView endUpdates];
                        self.timerPaused = NO;
                    });
                });
            }];
        }
    }
}

@end

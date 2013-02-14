//
//  BookmarkFeedViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 12/8/12.
//
//

#import <ASPinboard/ASPinboard.h>
#import "BookmarkFeedViewController.h"
#import "NSAttributedString+Attributes.h"
#import "AppDelegate.h"
#import "BookmarkCell.h"
#import "TSMiniWebBrowser.h"
#import "ZAActivityBar.h"
#import "FMDatabase.h"
#import "BookmarkViewController.h"
#import "PocketAPI.h"
#import "NSString+URLEncoding.h"
#import "OAuthConsumer.h"
#import "KeychainItemWrapper.h"

@interface BookmarkFeedViewController ()

@end

@implementation BookmarkFeedViewController

@synthesize sourceURL;
@synthesize bookmarks;
@synthesize strings;
@synthesize heights;
@synthesize date_formatter;
@synthesize webView;
@synthesize bookmark = _bookmark;
@synthesize bookmarkDetailViewController;
@synthesize selectedIndexPath;
@synthesize shouldShowContextMenu;
@synthesize longPressGestureRecognizer;

- (id)initWithURL:(NSString *)aURL {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.sourceURL = [NSURL URLWithString:aURL];
        self.bookmarks = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.date_formatter = [[NSDateFormatter alloc] init];
        [self.date_formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [self.date_formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        self.tableView.separatorColor = HEX(0xD1D1D1ff);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shouldShowContextMenu = YES;
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    failureCount = 0;

    if (![self becomeFirstResponder]) {
        DLog(@"Couldn't become first responder ");
        return;
    }
}


- (void)longPress:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan && self.shouldShowContextMenu) {
        CGPoint pressPoint;
        pressPoint = [recognizer locationInView:self.tableView];
        self.selectedIndexPath = [self.tableView indexPathForRowAtPoint:pressPoint];
        self.bookmark = self.bookmarks[self.selectedIndexPath.row];
        [self openActionSheetForBookmark:self.bookmark];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self processBookmarks];
}

#pragma mark - Gesture Recognizers

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark - Helpers

+ (NSNumber *)heightForBookmark:(NSDictionary *)bookmark {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];

    CGFloat height = 12.0f;
    height += ceilf([bookmark[@"title"] sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    
    if (![bookmark[@"description"] isEqualToString:@""]) {
        height += ceilf([bookmark[@"description"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        height += ceilf([bookmark[@"tags"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    return @(height);
}

+ (NSArray *)linksForBookmark:(NSDictionary *)bookmark {
    NSMutableArray *links = [NSMutableArray array];
    int location = [bookmark[@"title"] length] + 1;
    if (![bookmark[@"description"] isEqualToString:@""]) {
        location += [bookmark[@"description"] length] + 1;
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        for (NSString *tag in [bookmark[@"tags"] componentsSeparatedByString:@" "]) {
            NSRange range = [bookmark[@"tags"] rangeOfString:tag];
            [links addObject:@{@"url": [NSURL URLWithString:[tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], @"location": @(location+range.location), @"length": @(range.length)}];
        }
    }
    return links;
}

+ (NSMutableAttributedString *)attributedStringForBookmark:(NSDictionary *)bookmark {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", bookmark[@"title"]];
    NSRange titleRange = NSMakeRange(0, [bookmark[@"title"] length]);
    NSRange descriptionRange = {};
    NSRange tagRange = {};
    int newLineCount = 1;
    if (![bookmark[@"description"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"description"]]];
        descriptionRange = NSMakeRange(titleRange.length + newLineCount, [bookmark[@"description"] length]);
        newLineCount++;
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"tags"]]];
        tagRange = NSMakeRange(titleRange.length + descriptionRange.length + newLineCount, [bookmark[@"tags"] length]);
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    [attributedString setFont:largeHelvetica range:titleRange];
    [attributedString setFont:smallHelvetica range:descriptionRange];
    [attributedString setFont:smallHelvetica range:tagRange];
    [attributedString setTextColor:HEX(0x555555ff)];
    [attributedString setTextColor:HEX(0x2255aaff) range:titleRange];
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [attributedString setTextColor:HEX(0xcc2222ff) range:tagRange];
    }
    
    [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
    return attributedString;
}

- (void)processBookmarks {
    if (failureCount > 5) {
        #warning TODO
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:self.sourceURL];
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    [delegate setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [delegate setNetworkActivityIndicatorVisible:NO];

                               if ([(NSHTTPURLResponse *)response statusCode] == 403 && [self.sourceURL.absoluteString hasSuffix:@"network/"]) {
                                   ASPinboard *pinboard = [ASPinboard sharedInstance];
                                   [pinboard rssKeyWithSuccess:^(NSString *feedToken) {
                                       [delegate setToken:feedToken];
                                       NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                                       self.sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/network/", feedToken, username]];
                                       failureCount++;
                                       [self processBookmarks];
                                   }];
                               }
                               else if (!error) {
                                   NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

                                   [self.bookmarks removeAllObjects];
                                   [self.strings removeAllObjects];
                                   [self.heights removeAllObjects];
                                   
                                   for (NSDictionary *element in payload) {
                                       NSMutableDictionary *bookmark = [NSMutableDictionary dictionaryWithDictionary:@{
                                            @"title": element[@"d"],
                                            @"description": element[@"n"],
                                            @"url": element[@"u"],
                                            @"tags": [element[@"t"] componentsJoinedByString:@" "]
                                       }];
                                       
                                       if (bookmark[@"title"] == [NSNull null]) {
                                           bookmark[@"title"] = @"";
                                       }
                                       
                                       if (bookmark[@"description"] == [NSNull null]) {
                                           bookmark[@"description"] = @"";
                                       }

                                       [self.bookmarks addObject:bookmark];
                                       [self.heights addObject:[BookmarkFeedViewController heightForBookmark:bookmark]];
                                       [self.strings addObject:[BookmarkFeedViewController attributedStringForBookmark:bookmark]];
                                   }

                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self.tableView reloadData];
                                       });
                                   });
                               }
                           }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.heights count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSAttributedString *string;
    NSDictionary *bookmark;    
    string = self.strings[indexPath.row];
    bookmark = self.bookmarks[indexPath.row];

    [cell.textView setText:string];

    for (NSDictionary *link in [BookmarkFeedViewController linksForBookmark:bookmark]) {
        [cell.textView addLinkToURL:link[@"url"] withRange:NSMakeRange([link[@"location"] integerValue], [link[@"length"] integerValue])];
    }
    
    cell.textView.backgroundColor = HEX(0xffffffff);
    cell.contentView.backgroundColor = HEX(0xffffffff);

    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.heights[indexPath.row] floatValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.webView = [[UIWebView alloc] init];
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    self.bookmark = self.bookmarks[indexPath.row];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    switch ([[[AppDelegate sharedDelegate] browser] integerValue]) {
        case BROWSER_WEBVIEW: {
            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Webview"}];
            TSMiniWebBrowser *webBrowser = [[TSMiniWebBrowser alloc] initWithUrl:[NSURL URLWithString:self.bookmark[@"url"]]];
            webBrowser.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:webBrowser animated:YES];
            break;
        }
            
        case BROWSER_SAFARI: {
            [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Safari"}];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.bookmark[@"url"]]];
            break;
        }
            
        case BROWSER_CHROME:
            if ([self.bookmark[@"url"] hasPrefix:@"http"]) {
                NSURL *url = [NSURL URLWithString:[self.bookmark[@"url"] stringByReplacingCharactersInRange:[self.bookmark[@"url"] rangeOfString:@"http"] withString:@"googlechrome"]];
                [mixpanel track:@"Visited bookmark" properties:@{@"Browser": @"Chrome"}];
                [[UIApplication sharedApplication] openURL:url];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Lighthearted Disappointment", nil) message:NSLocalizedString(@"Google Chrome failed to open", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                [alert show];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - Menu Items

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
    if (!self.shouldShowContextMenu) {
        return NO;
    }

    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([[AppDelegate sharedDelegate] readlater] != nil) {
        if (action == @selector(readLater:)) {
            NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
            if ([bookmark[@"url"] rangeOfString:@"twitter.com"].location != NSNotFound || [bookmark[@"url"] rangeOfString:@"github.com"].location != NSNotFound) {
                return NO;
            }
            return YES;
        }
    }
    return (action == @selector(copyToMine:) || action == @selector(copyTitle:) || action == @selector(copyURL:) || action == @selector(editBookmark:) || action == @selector(deleteBookmark:));
}

- (void)copyToMine:(id)sender {
    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    [[AppDelegate sharedDelegate] showAddBookmarkViewControllerWithBookmark:bookmark update:@(NO) callback:nil];
    [[Mixpanel sharedInstance] track:@"Clicked copy to mine"];
}

- (void)copyTitle:(id)sender {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"Title copied to clipboard.", nil);
    notification.alertAction = @"Open Pushpin";
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    [[UIPasteboard generalPasteboard] setString:bookmark[@"title"]];
    [[Mixpanel sharedInstance] track:@"Copied title"];
}

- (void)copyURL:(id)sender {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = NSLocalizedString(@"URL copied to clipboard.", nil);
    notification.alertAction = @"Open Pushpin";
    notification.userInfo = @{@"success": @YES, @"updated": @NO};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    [[UIPasteboard generalPasteboard] setString:bookmark[@"url"]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)readLater:(id)sender {
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
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
        [parameters addObject:[OARequestParameter requestParameter:@"url" value:self.bookmark[@"url"]]];
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
        [request setParameters:@[[OARequestParameter requestParameter:@"url" value:self.bookmark[@"url"]]]];
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
        [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:self.bookmark[@"url"]]
                             withTitle:self.bookmark[@"title"]
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

- (void)share:(id)sender {
    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[bookmark[@"title"], bookmark[@"url"]] applicationActivities:nil];
    [self presentModalViewController:activityViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    self.selectedIndexPath = indexPath;
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
}

#pragma mark - Attributed String Delegate



- (void)attributedLabel:(TTTAttributedLabel *)label didStartTouchWithTextCheckingResult:(NSTextCheckingResult *)result {
    self.shouldShowContextMenu = NO;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didCancelTouchWithTextCheckingResult:(NSTextCheckingResult *)result {
    self.shouldShowContextMenu = YES;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    self.shouldShowContextMenu = YES;
    NSNumber *tag_id;
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    NSString *tag = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    FMResultSet *results = [db executeQuery:@"SELECT id FROM tag WHERE name=?" withArgumentsInArray:@[tag]];
    [results next];
    tag_id = [results objectForColumnIndex:0];
    [db close];
    
    BookmarkViewController *bookmarkViewController = [[BookmarkViewController alloc] initWithQuery:@"SELECT bookmark.* FROM bookmark LEFT JOIN tagging ON bookmark.id = tagging.bookmark_id LEFT JOIN tag ON tag.id = tagging.tag_id WHERE tag.id = :tag_id LIMIT :limit OFFSET :offset" parameters:[NSMutableDictionary dictionaryWithObjectsAndKeys:tag_id, @"tag_id", nil]];
    bookmarkViewController.title = tag;
    [self.navigationController pushViewController:bookmarkViewController animated:YES];
}

#pragma mark - Action Sheet Delegate

- (void)openActionSheetForBookmark:(NSDictionary *)bookmark {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:bookmark[@"url"] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSInteger cancelButtonIndex = 3;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT COUNT(*) FROM bookmark WHERE url=?" withArgumentsInArray:@[bookmark[@"url"]]];
    [results next];
    if ([results intForColumnIndex:0] == 0) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Copy to mine", nil)];
    }
    else {
        cancelButtonIndex--;
    }
    [db close];


    [sheet addButtonWithTitle:NSLocalizedString(@"Copy URL", nil)];
    // [sheet addButtonWithTitle:NSLocalizedString(@"Copy Title", nil)];

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
    else {
        cancelButtonIndex--;
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.cancelButtonIndex = cancelButtonIndex;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:NSLocalizedString(@"Send to Instapaper", nil)]) {
        [self readLater:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Readability", nil)]) {
        [self readLater:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Send to Pocket", nil)]) {
        [self readLater:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Copy URL", nil)]) {
        [self copyURL:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Copy Title", nil)]) {
        [self copyTitle:nil];
    }
    else if ([title isEqualToString:NSLocalizedString(@"Copy to mine", nil)]) {
        [self copyToMine:nil];
    }
}

@end

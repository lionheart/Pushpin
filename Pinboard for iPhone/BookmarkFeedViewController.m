//
//  BookmarkFeedViewController.m
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 12/8/12.
//
//

#import "BookmarkFeedViewController.h"
#import "NSAttributedString+Attributes.h"
#import "AppDelegate.h"
#import "BookmarkCell.h"
#import "TSMiniWebBrowser.h"
#import "WBSuccessNoticeView.h"
#import "ZAActivityBar.h"

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

    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handleSwipeRight:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.tableView addGestureRecognizer:recognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    failureCount = 0;

    if (![self becomeFirstResponder]) {
        NSLog(@"Couldn't become first responder ");
        return;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self processBookmarks];
    
    NSMutableArray *items = [NSMutableArray array];
    UIMenuItem *copyURLMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy URL", nil) action:@selector(copyURL:)];
    UIMenuItem *copyTitleMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Title", nil) action:@selector(copyTitle:)];
    UIMenuItem *shareMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Share", nil) action:@selector(share:)];
    UIMenuItem *copyToMineMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy to mine", nil) action:@selector(copyToMine:)];
    
    [items addObject:copyToMineMenuItem];

    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        UIMenuItem *readLaterMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Instapaper", nil) action:@selector(readLater:)];
        [items addObject:readLaterMenuItem];
    }
    else if (readLater.integerValue == READLATER_READABILITY) {
        UIMenuItem *readLaterMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Readability", nil) action:@selector(readLater:)];
        [items addObject:readLaterMenuItem];
    }
    
    [items addObject:copyURLMenuItem];
    [items addObject:copyTitleMenuItem];
    [items addObject:shareMenuItem];
    
    [[UIMenuController sharedMenuController] setMenuItems:items];
    [[UIMenuController sharedMenuController] update];
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
    
    CGFloat height = 10.0f;
    height += ceilf([bookmark[@"title"] sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    
    if (![bookmark[@"description"] isEqualToString:@""]) {
        height += ceilf([bookmark[@"description"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        height += ceilf([bookmark[@"tags"] sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
    }
    return @(height);
}

+ (NSMutableAttributedString *)attributedStringForBookmark:(NSDictionary *)bookmark {
    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", bookmark[@"title"]];
    if (![bookmark[@"description"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"description"]]];
    }
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [content appendString:[NSString stringWithFormat:@"\n%@", bookmark[@"tags"]]];
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    
    [attributedString setFont:largeHelvetica range:[content rangeOfString:bookmark[@"title"]]];
    [attributedString setFont:smallHelvetica range:[content rangeOfString:bookmark[@"description"]]];
    [attributedString setTextColor:HEX(0x555555ff)];
    [attributedString setTextColor:HEX(0x2255aaff) range:[content rangeOfString:bookmark[@"title"]]];
    
    if (![bookmark[@"tags"] isEqualToString:@""]) {
        [attributedString setTextColor:HEX(0xcc2222ff) range:[content rangeOfString:bookmark[@"tags"]]];
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
    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];

                               if ([(NSHTTPURLResponse *)response statusCode] == 403 && [self.sourceURL.absoluteString hasSuffix:@"network/"]) {
                                   [[AppDelegate sharedDelegate] updateFeedToken:^{
                                       NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
                                       NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
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
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    [ZAActivityBar showSuccessWithStatus:NSLocalizedString(@"Title copied to clipboard.", nil)];

    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    [[UIPasteboard generalPasteboard] setString:bookmark[@"title"]];
    [[Mixpanel sharedInstance] track:@"Copied title"];
}

- (void)copyURL:(id)sender {
    [ZAActivityBar showSuccessWithStatus:NSLocalizedString(@"URL copied to clipboard.", nil)];

    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    [[UIPasteboard generalPasteboard] setString:bookmark[@"url"]];
    [[Mixpanel sharedInstance] track:@"Copied URL"];
}

- (void)readLater:(id)sender {
    NSDictionary *bookmark = self.bookmarks[self.selectedIndexPath.row];
    NSNumber *readLater = [[AppDelegate sharedDelegate] readlater];
    NSURL *url = [NSURL URLWithString:bookmark[@"url"]];
    NSString *scheme = [NSString stringWithFormat:@"%@://", url.scheme];
    if (readLater.integerValue == READLATER_INSTAPAPER) {
        NSURL *newURL = [NSURL URLWithString:[bookmark[@"url"] stringByReplacingCharactersInRange:[bookmark[@"url"] rangeOfString:scheme] withString:@"x-callback-instapaper://x-callback-url/add?x-source=Pushpin&x-success=pushpin://&url="]];
        [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
        [[UIApplication sharedApplication] openURL:newURL];
    }
    else {
        NSURL *newURL = [NSURL URLWithString:[bookmark[@"url"] stringByReplacingCharactersInRange:[bookmark[@"url"] rangeOfString:scheme] withString:@"readability://add/"]];
        [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
        [[UIApplication sharedApplication] openURL:newURL];
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

@end

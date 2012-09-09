//
//  PostViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Pinboard.h"
#import "OHAttributedLabel.h"
#import "TTTAttributedLabel.h"
#import <CoreData/CoreData.h>

@interface BookmarkViewController : UITableViewController <UIWebViewDelegate, TTTAttributedLabelDelegate, PinboardDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) NSMutableArray *bookmarks;
@property (nonatomic, retain) NSMutableArray *filteredBookmarks;
@property (nonatomic, retain) NSString *savedSearchTerm;
@property (nonatomic, retain) NSString *endpoint;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSMutableArray *strings;
@property (nonatomic, retain) NSMutableArray *heights;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSPredicate *predicate;
@property (nonatomic, retain) NSDateFormatter *date_formatter;
@property (nonatomic, retain) UISearchDisplayController *searchDisplayController;
@property (nonatomic) BOOL searchWasActive;

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters;
- (id)initWithEndpoint:(NSString *)endpoint predicate:(NSPredicate *)predicate parameters:(NSDictionary *)parameters;
- (void)refreshBookmarks;
- (Bookmark *)updateBookmark:(Bookmark *)bookmark withAttributes:(NSDictionary *)attributes;
- (void)processBookmarks;

@end

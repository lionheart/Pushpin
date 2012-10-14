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
#import "PullToRefreshView.h"
#import "FMDatabase.h"
#import "AppDelegate.h"

@class FMResultSet;

@interface BookmarkViewController : UITableViewController <UIWebViewDelegate, TTTAttributedLabelDelegate, PullToRefreshViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate> {
    PullToRefreshView *pull;
}

@property (nonatomic, retain) NSNumber *limit;
@property (nonatomic, retain) NSMutableArray *bookmarks;
@property (nonatomic, retain) NSMutableArray *filteredBookmarks;
@property (nonatomic, retain) NSString *savedSearchTerm;
@property (nonatomic, retain) NSString *endpoint;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSMutableArray *strings;
@property (nonatomic, retain) NSMutableArray *heights;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSDateFormatter *date_formatter;
@property (nonatomic, retain) UISearchDisplayController *searchDisplayController;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *query;
@property (nonatomic, retain) NSMutableDictionary *queryParameters;
@property (nonatomic) BOOL searchWasActive;

- (FMResultSet *)resultSetForDB:(FMDatabase *)db;
- (id)initWithQuery:(NSString *)query parameters:(NSMutableDictionary *)parameters;
- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters;
- (void)refreshBookmarks;
- (void)processBookmarks;
- (void)processBookmark:(NSDictionary *)dictionary;
- (void)edit;
- (void)stopEditing;
- (void)toggleEditMode;
- (void)reloadTableData;

@end

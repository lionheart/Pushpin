//
//  PostViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OHAttributedLabel.h"
#import "TTTAttributedLabel.h"
#import <CoreData/CoreData.h>
#import "FMDatabase.h"
#import "AppDelegate.h"

@class FMResultSet;

@interface BookmarkViewController : UITableViewController <UIWebViewDelegate, TTTAttributedLabelDelegate, UISearchDisplayDelegate, UISearchBarDelegate, BookmarkUpdateProgressDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
}

@property (nonatomic, retain) UIViewController *bookmarkDetailViewController;
@property (nonatomic, retain) NSDictionary *bookmark;
@property (nonatomic, retain) NSNumber *limit;
@property (nonatomic, retain) NSMutableArray *bookmarks;
@property (nonatomic, retain) NSMutableArray *filteredBookmarks;
@property (nonatomic, retain) NSMutableArray *filteredStrings;
@property (nonatomic, retain) NSMutableArray *filteredHeights;
@property (nonatomic, retain) NSMutableArray *filteredLinks;
@property (nonatomic, retain) NSMutableArray *links;
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
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) UIAlertView *confirmDeleteAlertView;
@property (nonatomic) BOOL searchWasActive;

- (void)openActionSheetForBookmark:(NSDictionary *)bookmark;
- (FMResultSet *)resultSetForDB:(FMDatabase *)db;
+ (NSArray *)linksForBookmark:(NSDictionary *)bookmark;
+ (NSNumber *)heightForBookmark:(NSDictionary *)bookmark;
+ (NSMutableAttributedString *)attributedStringForBookmark:(NSDictionary *)bookmark;
- (id)initWithQuery:(NSString *)query parameters:(NSMutableDictionary *)parameters;
- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters;
- (void)refreshBookmarks;
- (void)processBookmarks;
- (void)processBookmark:(NSDictionary *)dictionary;
- (void)markBookmarkAsRead:(id)sender;
- (void)edit;
- (void)stopEditing;
- (void)toggleEditMode;
- (void)reloadTableData;
- (void)longPress:(UIGestureRecognizer *)recognizer;
- (void)updateSearchResults;
- (void)updateData;
- (void)bookmarkUpdated:(NSNotification *)notification;

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer;

- (void)confirmDeletion:(id)sender;
- (void)deleteBookmark:(id)sender;
- (void)editBookmark:(id)sender;
- (void)copyURL:(id)sender;
- (void)copyTitle:(id)sender;
- (void)readLater:(id)sender;
- (void)share:(id)sender;

@end

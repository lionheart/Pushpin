//
//  NoteViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/8/12.
//
//

#import <UIKit/UIKit.h>

@interface NoteViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) NSArray *notes;
@property (nonatomic, retain) NSMutableArray *filteredNotes;
@property (nonatomic, retain) UISearchDisplayController *searchDisplayController;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIViewController *noteDetailViewController;
@property (nonatomic, retain) UIWebView *webView;

@end

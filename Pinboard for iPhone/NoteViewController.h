//
//  NoteViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/8/12.
//
//

#import <UIKit/UIKit.h>

@interface NoteViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) NSMutableArray *notes;
@property (nonatomic, retain) UISearchDisplayController *searchDisplayController;

@end

//
//  PPSavedFeedsViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import "PPTableViewController.h"
#import "AppDelegate.h"

@interface PPSavedFeedsViewController : PPTableViewController

@property (nonatomic, strong) NSMutableArray *feeds;

- (void)addSavedFeedButtonTouchUpInside:(id)sender;

@end

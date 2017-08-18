//
//  PPTableViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/19/13.
//
//

@import UIKit;

@interface PPTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

- (id)initWithStyle:(UITableViewStyle)style;

@end

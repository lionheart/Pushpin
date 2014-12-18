//
//  PPTableViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/19/13.
//
//

@import UIKit;

@interface PPTableViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

- (id)initWithStyle:(UITableViewStyle)style;

@end

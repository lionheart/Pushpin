//
//  HomeViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDatabase.h"

@interface HomeViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) BOOL connectionAvailable;

- (void)connectionStatusDidChange:(NSNotification *)notification;

@end

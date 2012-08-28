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

@interface BookmarkViewController : UITableViewController <UIWebViewDelegate, TTTAttributedLabelDelegate, PinboardDelegate>

@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSMutableArray *bookmarks;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSMutableArray *strings;
@property (nonatomic, retain) NSMutableArray *heights;

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters;

@end

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

@interface BookmarkViewController : UITableViewController <UIWebViewDelegate, OHAttributedLabelDelegate, PinboardDelegate>

@property (nonatomic, retain) NSMutableArray *bookmarks;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSMutableArray *labels;

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters;

@end

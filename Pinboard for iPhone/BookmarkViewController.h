//
//  PostViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BookmarkViewController : UITableViewController <UIWebViewDelegate>

@property (nonatomic, retain) NSMutableArray *posts;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSMutableDictionary *heights;
@property (nonatomic, retain) NSMutableArray *webViews;
@property (nonatomic, retain) NSMutableArray *loadedWebViews;

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters;

@end

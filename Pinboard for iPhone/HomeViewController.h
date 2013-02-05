//
//  HomeViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FeedListViewController;
@class NoteViewController;
@class TagViewController;

@interface HomeViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) FeedListViewController *feedListViewController;
@property (nonatomic, retain) NoteViewController *noteViewController;
@property (nonatomic, retain) TagViewController *tagViewController;
@property (nonatomic, retain) UITableViewController *activeViewController;
@property (nonatomic, retain) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer;

@end

//
//  HomeViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HomeViewController.h"
#import "FeedListViewController.h"
#import "NoteViewController.h"
#import "TagViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

@synthesize feedListViewController;
@synthesize leftSwipeGestureRecognizer;
@synthesize noteViewController;
@synthesize activeViewController;
@synthesize scrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.canCancelContentTouches = NO;
    self.scrollView.delaysContentTouches = NO;
    self.scrollView.delegate = self;
    
    self.feedListViewController = [[FeedListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.feedListViewController.tableView.frame = CGRectMake(0, 0, 320, height);
    self.feedListViewController.navigationController = self.navigationController;
    
    self.noteViewController = [[NoteViewController alloc] init];
    self.noteViewController.view.frame = CGRectMake(640, 0, 320, height);
    self.noteViewController.navigationController = self.navigationController;

    self.tagViewController = [[TagViewController alloc] initWithStyle:UITableViewStylePlain];
    self.tagViewController.view.frame = CGRectMake(320, 0, 320, height);
    self.tagViewController.navigationController = self.navigationController;
    
    self.scrollView.contentSize = CGSizeMake(320*3, self.feedListViewController.tableView.contentSize.height);
    self.scrollView.frame = CGRectMake(0, 0, 320, height);
    
    UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
    pageControl.numberOfPages = 3;
    pageControl.currentPage = 1;
    pageControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.view addSubview:pageControl];
    [self.scrollView addSubview:self.feedListViewController.tableView];
    [self.scrollView addSubview:self.tagViewController.view];
    [self.scrollView addSubview:self.noteViewController.view];
    [self.view addSubview:self.scrollView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.feedListViewController viewWillAppear:animated];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSUInteger pageNum = floor(((self.scrollView.contentOffset.x - 160) / 320) + 1);
    if (pageNum == 0) {
        self.title = NSLocalizedString(@"Browse Tab Bar Title", nil);
    }
    else if (pageNum == 1) {
        self.title = @"Tags";
    }
    else {
        self.title = @"Notes";
    }
}

@end

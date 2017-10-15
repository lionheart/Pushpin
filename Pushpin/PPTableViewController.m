//
//  PPTableViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/19/13.
//
//

@import LHSCategoryCollection;

#import "PPTableViewController.h"

@interface PPTableViewController ()

@property (nonatomic) UITableViewStyle style;
@property (nonatomic, strong) NSLayoutConstraint *keyboardAdjustingBottomConstraint;

@end

@implementation PPTableViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super init];
    if (self) {
        self.style = style;
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:self.style];
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
        self.tableView.backgroundColor = HEX(0xF7F9FDff);
        self.tableView.opaque = NO;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;

        if (@available(iOS 11, *)) {
            self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.tableView];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    NSDictionary *views = @{@"table": self.tableView};
    [self.tableView lhs_fillWidthOfSuperview];
    [self.view lhs_addConstraints:@"V:|[table]|" views:views];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortrait;
}

@end

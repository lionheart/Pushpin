//
//  PPLoginViewController.m
//  Pushpin
//
//  Created by Eric Olszewski on 6/26/15.
//  Copyright (c) 2015 Lionheart Software. All rights reserved.
//

#import "PPLoginViewController.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>
#import <LHSTableViewCells/LHSTableViewCellDefault.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>
#import <LHSKeyboardAdjusting/UIViewController+LHSKeyboardAdjustment.h>
#import <LHSCategoryCollection/UIAlertController+LHSAdditions.h>
@import uservoice_iphone_sdk;
#import "PPMailChimp.h"

#import "PPPinboardLoginViewController.h"

static NSString * const CellIdentifier = @"CellIdentifier";

@interface PPLoginViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;

@end

@implementation PPLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Pushpin";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];

    NSDictionary *views = @{@"top": self.topLayoutGuide,
                            @"table": self.tableView};
    
    [self.view addSubview:self.tableView];
    
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.bottomLayoutGuide
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1
                                                          constant:0];
    
    [self.view addConstraint:self.bottomConstraint];
    [self.view lhs_addConstraints:@"V:[top][table]" views:views];
    [self.tableView lhs_fillWidthOfSuperview];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Help", nil)
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(showContactForm)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self lhs_activateKeyboardAdjustment];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self lhs_deactivateKeyboardAdjustment];
}

#pragma mark - LHSKeyboardAdjusting

- (NSLayoutConstraint *)keyboardAdjustingBottomConstraint {
    return self.bottomConstraint;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    switch ((PPLoginServiceRowType)indexPath.row) {
        case PPLoginPinboardRow:
            cell.textLabel.text = @"Pinboard.in";
            cell.imageView.image = [UIImage imageNamed:@"pinboard-logo"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;

        case PPLoginPushpinRow:
            cell.textLabel.text = @"Pushpin Cloud";
            cell.detailTextLabel.text = @"Coming Soon. Click here to sign up!";
            cell.imageView.image = [UIImage imageNamed:@"pushpin-cloud-logo"];
            break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Choose your service";
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ((PPLoginServiceRowType)indexPath.row) {
        case PPLoginPinboardRow: {
            PPPinboardLoginViewController *pinboardLoginViewController = [[PPPinboardLoginViewController alloc] init];
            [self.navigationController pushViewController:pinboardLoginViewController
                                                 animated:YES];
            break;
        }
            
        case PPLoginPushpinRow: {
            UIAlertController *alert = [PPMailChimp mailChimpSubscriptionAlertController];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
    }
}

#pragma mark - Utils

- (void)showContactForm {
    UVConfig *config = [UVConfig configWithSite:@"lionheartsw.uservoice.com"
                                         andKey:@"9pBeLUHkDPLj3XhBG9jQ"
                                      andSecret:@"PaXdmNmtTAynLJ1MpuOFnVUUpfD2qA5obo7NxhsxP5A"];
    
    [UserVoice presentUserVoiceContactUsFormForParentViewController:self andConfig:config];
}

@end

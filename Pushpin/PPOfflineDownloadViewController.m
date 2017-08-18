//
//  PPOfflineDownloadViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/1/15.
//  Copyright (c) 2015 Lionheart Software. All rights reserved.
//

@import LHSCategoryCollection;
@import LHSTableViewCells;

#import "PPOfflineDownloadViewController.h"
#import "PPURLCache.h"
#import "PPAppDelegate.h"
#import "PPTheme.h"
#import "NSString+Additions.h"
#import "PPPinboardMetadataCache.h"

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPOfflineDownloadViewController ()

@property (nonatomic, strong) UIProgressView *htmlProgressView;
@property (nonatomic, strong) UIProgressView *assetProgressView;

@property (nonatomic, strong) UILabel *assetLabel;
@property (nonatomic, strong) UILabel *htmlLabel;

@property (nonatomic, strong) UILabel *assetDetail;
@property (nonatomic, strong) UILabel *htmlDetail;

@property (nonatomic) NSInteger numberOfStaticAssets;
@property (nonatomic) BOOL downloadInProgress;

- (void)dismissViewController;

@end

@implementation PPOfflineDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Downloading", nil);
    self.view.backgroundColor = HEX(0xF7F9FDFF);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(dismissViewController)];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activity startAnimating];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];
    self.numberOfStaticAssets = 0;
    self.downloadInProgress = YES;

    self.assetProgressView = [[UIProgressView alloc] init];
    self.assetProgressView.progress = 0;
    self.assetProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.htmlProgressView = [[UIProgressView alloc] init];
    self.htmlProgressView.progress = 0;
    self.htmlProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.assetDetail = [[UILabel alloc] init];
    self.assetDetail.font = [PPTheme detailLabelFontAlternate1];
    self.assetDetail.translatesAutoresizingMaskIntoConstraints = NO;

    self.htmlDetail = [[UILabel alloc] init];
    self.htmlDetail.font = [PPTheme detailLabelFontAlternate1];
    self.htmlDetail.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.assetLabel = [[UILabel alloc] init];
    self.assetLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.assetLabel.backgroundColor = [UIColor whiteColor];
    self.assetLabel.font = [PPTheme textLabelFont];
    
    self.htmlLabel = [[UILabel alloc] init];
    self.htmlLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.htmlLabel.backgroundColor = [UIColor whiteColor];
    self.htmlLabel.font = [PPTheme textLabelFont];
    
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    void (^Completion)() = ^{
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Done", nil);
        self.navigationItem.leftBarButtonItem = nil;
        
        self.htmlLabel.text = NSLocalizedString(@"Download complete!", nil);
        self.htmlDetail.text = @"100%";
        [self.htmlProgressView setProgress:1 animated:NO];
        self.downloadInProgress = NO;
        
        [self.tableView reloadData];
        
        [[PPPinboardMetadataCache sharedCache] removeAllObjects];
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PPURLCache *cache = [PPAppDelegate sharedDelegate].urlCache;
        [cache initiateBackgroundDownloadsWithCompletion:^(NSInteger count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (count == 0) {
                    Completion();
                }
            });
        } progress:^(NSString *urlString, NSString *assetURLString, NSInteger htmlCurrent, NSInteger htmlTotal, NSInteger assetCurrent, NSInteger assetTotal) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger oldStaticAssetTotal = self.numberOfStaticAssets;

                if (assetTotal != oldStaticAssetTotal) {
                    @try {
                        self.numberOfStaticAssets = assetTotal;

                        if (assetTotal == 0) {
                            [self.tableView beginUpdates];
                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView endUpdates];
                        } else if (oldStaticAssetTotal == 0) {
                            [self.tableView beginUpdates];
                            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView endUpdates];
                        } else if (!self.downloadInProgress && oldStaticAssetTotal > 0) {
                            [self.tableView beginUpdates];
                            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView endUpdates];
                        }
                    }
                    @catch (NSException *exception) {
                        [self.tableView reloadData];
                    }
                }

                if (htmlCurrent < htmlTotal || assetCurrent < assetTotal) {
                    static NSNumberFormatter *formatter;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        formatter = [[NSNumberFormatter alloc] init];
                        formatter.numberStyle = NSNumberFormatterPercentStyle;
                        formatter.minimumFractionDigits = 1;
                    });

                    float htmlProgress = (float)htmlCurrent / (float)htmlTotal;
                    float assetProgress;
                    if (assetTotal > 0) {
                        assetProgress = (float)assetCurrent / (float)assetTotal;
                        [self.assetProgressView setProgress:assetProgress animated:YES];
                        self.assetLabel.text = [NSString stringWithFormat:@"%lu / %lu", (long)assetCurrent, (long)assetTotal];
                    } else {
                        assetProgress = 0;
                        [self.assetProgressView setProgress:assetProgress animated:NO];
                    }

                    self.htmlDetail.text = [formatter stringFromNumber:@(htmlProgress)];
                    self.htmlLabel.text = [urlString originalURLString];
                    [self.htmlProgressView setProgress:htmlProgress animated:YES];
                } else {
                    Completion();
                }
            });
        }];
    });
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"HTML";
    } else {
        return NSLocalizedString(@"Static Assets", nil);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    [cell.contentView lhs_removeSubviews];

    NSDictionary *views;
    UIProgressView *progress;
    UILabel *label;
    UILabel *detail;
    if (indexPath.section == 0) {
        progress = self.htmlProgressView;
        label = self.htmlLabel;
        detail = self.htmlDetail;

        views = @{@"progress": progress,
                  @"label": label,
                  @"detail": detail };

        [cell.contentView addSubview:progress];
        [cell.contentView addSubview:label];
        [cell.contentView addSubview:detail];

        [progress lhs_fillWidthOfSuperview];
        [cell.contentView lhs_addConstraints:@"V:|-4-[label][detail]-3-[progress(8)]|" views:views];
        [cell.contentView lhs_addConstraints:@"H:|-10-[label]-10-|" views:views];
        [cell.contentView lhs_addConstraints:@"H:|-10-[detail]-10-|" views:views];
    } else {
        progress = self.assetProgressView;
        label = self.assetLabel;
        detail = self.assetDetail;

        views = @{@"progress": progress,
                  @"label": label,
                  @"detail": detail };

        [cell.contentView addSubview:progress];
        [cell.contentView addSubview:label];

        [progress lhs_fillWidthOfSuperview];
        [cell.contentView lhs_addConstraints:@"V:|-4-[label]-3-[progress(8)]|" views:views];
        [cell.contentView lhs_addConstraints:@"H:|-10-[label]-10-|" views:views];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 60;
    }
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.numberOfStaticAssets > 0 && self.downloadInProgress) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (void)dismissViewController {
    [[PPAppDelegate sharedDelegate].urlCache stopAllDownloads];
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

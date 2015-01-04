//
//  PPOfflineDownloadViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/1/15.
//  Copyright (c) 2015 Lionheart Software. All rights reserved.
//

#import "PPOfflineDownloadViewController.h"
#import "PPURLCache.h"
#import "PPAppDelegate.h"
#import "PPTheme.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPOfflineDownloadViewController ()

@property (nonatomic, strong) UIProgressView *htmlProgressView;
@property (nonatomic, strong) UIProgressView *assetProgressView;

@property (nonatomic, strong) UILabel *assetLabel;
@property (nonatomic, strong) UILabel *htmlLabel;

@end

@implementation PPOfflineDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = HEX(0xF7F9FDFF);

    self.assetProgressView = [[UIProgressView alloc] init];
    self.assetProgressView.progress = 0;
    self.assetProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.htmlProgressView = [[UIProgressView alloc] init];
    self.htmlProgressView.progress = 0;
    self.htmlProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.assetLabel = [[UILabel alloc] init];
    self.assetLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.htmlLabel = [[UILabel alloc] init];
    self.htmlLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.tableView registerClass:[LHSTableViewCellSubtitle class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PPURLCache *cache = [PPAppDelegate sharedDelegate].urlCache;
        [cache initiateBackgroundDownloadsWithCompletion:^(NSInteger count) {
        } progress:^(NSInteger htmlCurrent, NSInteger htmlTotal, NSInteger assetCurrent, NSInteger assetTotal) {
            dispatch_async(dispatch_get_main_queue(), ^{
                float htmlProgress = (float)htmlCurrent / (float)htmlTotal;
                
                float assetProgress;
                if (assetTotal > 0) {
                    assetProgress = (float)assetCurrent / (float)assetTotal;
                }
                else {
                    assetProgress = 0;
                }

                [self.assetProgressView setProgress:assetProgress animated:YES];
                [self.htmlProgressView setProgress:htmlProgress animated:YES];
                
                NSDictionary *attributes = @{NSFontAttributeName: [PPTheme detailLabelFont]};
                NSMutableAttributedString *htmlString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"HTML\n%f", htmlProgress]
                                                                                               attributes:attributes];
                [htmlString addAttribute:NSFontAttributeName value:[PPTheme textLabelFont] range:NSMakeRange(0, 4)];

                NSMutableAttributedString *assetString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"CSS, JS, & Images\n%f", assetProgress]
                                                                                                attributes:attributes];
                [assetString addAttribute:NSFontAttributeName value:[PPTheme textLabelFont] range:NSMakeRange(0, 17)];

                self.htmlLabel.attributedText = htmlString;
                self.assetLabel.attributedText = assetString;
            });
        }];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.font = [PPTheme textLabelFont];
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    [cell.contentView lhs_removeSubviews];
    
    UIProgressView *progressView;
    UILabel *label;
    if (indexPath.section == 0) {
        progressView = self.htmlProgressView;
        label = self.htmlLabel;
    }
    else {
        progressView = self.assetProgressView;
        label = self.assetLabel;
    }

    if (indexPath.row == 0) {
        [cell.contentView addSubview:label];
        [label lhs_fillWidthOfSuperview];
        [label lhs_fillHeightOfSuperview];
    }
    else {
        [cell.contentView addSubview:progressView];
        [progressView lhs_fillHeightOfSuperview];
        [progressView lhs_fillWidthOfSuperview];
    }

    return cell;
}

@end

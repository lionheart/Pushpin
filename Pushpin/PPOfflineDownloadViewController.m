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
#import "NSString+Additions.h"

#import <LHSCategoryCollection/UIView+LHSAdditions.h>
#import <LHSTableViewCells/LHSTableViewCellSubtitle.h>

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPOfflineDownloadViewController ()

@property (nonatomic, strong) UIProgressView *htmlProgressView;
@property (nonatomic, strong) UIProgressView *assetProgressView;

@property (nonatomic, strong) UILabel *assetLabel;
@property (nonatomic, strong) UILabel *htmlLabel;

- (void)dismissViewController;

@end

@implementation PPOfflineDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Downloading";
    self.view.backgroundColor = HEX(0xF7F9FDFF);
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Stop"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(dismissViewController)];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activity startAnimating];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];

    self.assetProgressView = [[UIProgressView alloc] init];
    self.assetProgressView.progress = 0;
    self.assetProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.htmlProgressView = [[UIProgressView alloc] init];
    self.htmlProgressView.progress = 0;
    self.htmlProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *assetName = [[UILabel alloc] init];
    assetName.font = [PPTheme textLabelFont];
    assetName.text = @"CSS, JS, & Images";
    assetName.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *htmlName = [[UILabel alloc] init];
    htmlName.font = [PPTheme textLabelFont];
    htmlName.text = @"HTML";
    htmlName.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.assetLabel = [[UILabel alloc] init];
    self.assetLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.assetLabel.backgroundColor = [UIColor whiteColor];
    self.assetLabel.font = [PPTheme detailLabelFontAlternate1];
    self.assetLabel.text = @"0 / 0";
    
    self.htmlLabel = [[UILabel alloc] init];
    self.htmlLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.htmlLabel.backgroundColor = [UIColor whiteColor];
    self.htmlLabel.font = [PPTheme detailLabelFontAlternate1];
    self.htmlLabel.text = @"0%";
    
    UIView *htmlContainer = [[UIView alloc] init];
    htmlContainer.translatesAutoresizingMaskIntoConstraints = NO;
    htmlContainer.backgroundColor = [UIColor whiteColor];
    
    UIView *assetContainer = [[UIView alloc] init];
    assetContainer.translatesAutoresizingMaskIntoConstraints = NO;
    assetContainer.backgroundColor = [UIColor whiteColor];

    NSDictionary *views = @{@"assetProgress": self.assetProgressView,
                            @"htmlProgress": self.htmlProgressView,
                            @"asset": self.assetLabel,
                            @"html": self.htmlLabel,
                            @"assetName": assetName,
                            @"htmlName": htmlName,
                            @"htmlContainer": htmlContainer,
                            @"assetContainer": assetContainer };

    [htmlContainer addSubview:htmlName];
    [htmlContainer addSubview:self.htmlLabel];
    [htmlContainer addSubview:self.htmlProgressView];

    [assetContainer addSubview:assetName];
    [assetContainer addSubview:self.assetLabel];
    [assetContainer addSubview:self.assetProgressView];

    [assetContainer lhs_addConstraints:@"V:|-4-[assetName][asset]-3-[assetProgress(10)]|" views:views];
    [assetContainer lhs_addConstraints:@"H:|-10-[asset]-10-|" views:views];
    [assetContainer lhs_addConstraints:@"H:|-10-[assetName]-10-|" views:views];

    [htmlContainer lhs_addConstraints:@"V:|-4-[htmlName][html]-3-[htmlProgress(10)]|" views:views];
    [htmlContainer lhs_addConstraints:@"H:|-10-[html]-10-|" views:views];
    [htmlContainer lhs_addConstraints:@"H:|-10-[htmlName]-10-|" views:views];

    [self.assetProgressView lhs_fillWidthOfSuperview];
    [self.htmlProgressView lhs_fillWidthOfSuperview];
    
    [self.view addSubview:assetContainer];
    [self.view addSubview:htmlContainer];
    
    [self.view lhs_addConstraints:@"V:|-20-[htmlContainer]-20-[assetContainer]" views:views];
    [assetContainer lhs_fillWidthOfSuperview];
    [htmlContainer lhs_fillWidthOfSuperview];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PPURLCache *cache = [PPAppDelegate sharedDelegate].urlCache;
        [cache initiateBackgroundDownloadsWithCompletion:^(NSInteger count) {
        } progress:^(NSString *urlString, NSInteger htmlCurrent, NSInteger htmlTotal, NSInteger assetCurrent, NSInteger assetTotal) {
            dispatch_async(dispatch_get_main_queue(), ^{
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
                }
                else {
                    assetProgress = 0;
                    [self.assetProgressView setProgress:assetProgress animated:NO];
                    self.assetLabel.text = @"-";
                }

//                self.htmlLabel.text = [formatter stringFromNumber:@(htmlProgress)];
                self.htmlLabel.text = [urlString originalURLString];
                [self.htmlProgressView setProgress:htmlProgress animated:YES];
            });
        }];
    });
}

- (void)dismissViewController {
    [[PPAppDelegate sharedDelegate].urlCache stopAllDownloads];
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

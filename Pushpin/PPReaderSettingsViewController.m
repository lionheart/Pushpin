//
//  PPMobilizerSettingsViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/15/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPReaderSettingsViewController.h"
#import "PPTitleButton.h"
#import "PPTheme.h"

#import <LHSFontSelectionViewController/LHSFontSelectionViewController.h>
#import <LHSTableViewCells/LHSTableViewCellValue1.h>

static NSString *CellIdentifier = @"Cell";

@interface PPReaderSettingsViewController ()

@end

@implementation PPReaderSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PPTitleButton *titleView = [PPTitleButton button];
    [titleView setTitle:NSLocalizedString(@"Reader Settings", nil) imageName:nil];
    self.navigationItem.titleView = titleView;
    
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.font = [PPTheme textLabelFont];
    cell.detailTextLabel.font = [PPTheme detailLabelFont];
    cell.detailTextLabel.text = nil;
    cell.textLabel.text = nil;
    cell.accessoryView = nil;

    switch ((PPReaderSettingsRowType)indexPath.row) {
        case PPReaderSettingsRowFontFamily:
            cell.textLabel.text = @"Font Family";
            break;
            
        case PPReaderSettingsRowFontSize:
            cell.textLabel.text = @"Font size";
            break;

        case PPReaderSettingsRowFontImages:
            cell.textLabel.text = @"Display images?";
            break;
            
        case PPReaderSettingsRowFontLineSpacing:
            cell.textLabel.text = @"Line spacing";
            break;
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return PPReaderSettingsRowCount;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ((PPReaderSettingsRowType)indexPath.row) {
        case PPReaderSettingsRowFontFamily: {
            NSArray *preferredFontNames = @[@"AvenirNext-Regular", @"HelveticaNeue-Light", @"Arial", @"Georgia", @"Courier", @"Futura-Medium", @"GillSans-Light", @"Verdana"];
            LHSFontSelectionViewController *fontSelectionViewController = [[LHSFontSelectionViewController alloc] initWithPreferredFontNames:preferredFontNames
                                                                                                                      onlyShowPreferredFonts:YES];
            fontSelectionViewController.delegate = self;
            [self.navigationController pushViewController:fontSelectionViewController animated:YES];
            break;
        }
            
        case PPReaderSettingsRowFontSize:
            break;
            
        case PPReaderSettingsRowFontImages:
            break;
            
        case PPReaderSettingsRowFontLineSpacing:
            break;
    }
}

#pragma mark - LHSFontSelecting

- (void)setFontName:(NSString *)fontName forFontSelectionViewController:(LHFontSelectionViewController *)viewController {
    PPSettings *settings = [PPSettings sharedSettings];
    PPReaderSettings *readerSettings = settings.readerSettings;
    readerSettings.headerFontName = fontName;
    readerSettings.fontName = fontName;
    readerSettings.lineSpacing = 1.1;
    settings.readerSettings = readerSettings;
    [settings.readerSettings updateCustomReaderCSSFile];
}

- (NSString *)fontNameForFontSelectionViewController:(LHFontSelectionViewController *)viewController {
    return @"Helvetica";
}

- (CGFloat)fontSizeForFontSelectionViewController:(LHFontSelectionViewController *)viewController {
    return [PPTheme fontSize];
}

@end

//
//  PPAddSavedFeedViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/30/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "PPAddSavedFeedViewController.h"
#import "PinboardFeedDataSource.h"
#import "PPTheme.h"

#import "NSString+URLEncoding2.h"

#import <LHSCategoryCollection/UIImage+LHSAdditions.h>

static NSString *CellIdentifier = @"Cell";

@interface PPAddSavedFeedViewController ()

@end

@implementation PPAddSavedFeedViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIFont *font = [UIFont fontWithName:[PPTheme fontName] size:16];
    self.userTextField = [[UITextField alloc] init];
    self.userTextField.font = font;
    self.userTextField.delegate = self;
    self.userTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.userTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.userTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.userTextField.placeholder = NSLocalizedString(@"Username", nil);
    self.tagsTextField.returnKeyType = UIReturnKeyNext;
    self.userTextField.text = @"";

    self.tagsTextField = [[UITextField alloc] init];
    self.tagsTextField.font = font;
    self.tagsTextField.delegate = self;
    self.tagsTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.tagsTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tagsTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tagsTextField.placeholder = NSLocalizedString(@"Tags, separated by spaces", nil);
    self.tagsTextField.returnKeyType = UIReturnKeyDone;
    self.tagsTextField.text = @"";
    
    // Add a close and save button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeButtonTouchUpInside:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(addButtonTouchUpInside:)];

    self.title = NSLocalizedString(@"Add Feed", nil);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.userTextField becomeFirstResponder];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    CGRect frame = cell.frame;
    if (indexPath.row == 0) {
        cell.imageView.image = [[UIImage imageNamed:@"single-person"] lhs_imageWithColor:[UIColor darkGrayColor]];
        self.userTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
        [cell.contentView addSubview:self.userTextField];
    }
    else {
        cell.imageView.image = [[UIImage imageNamed:@"single-tag"] lhs_imageWithColor:[UIColor darkGrayColor]];
        self.tagsTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
        [cell.contentView addSubview:self.tagsTextField];
    }

    return cell;
}

#pragma mark Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.tagsTextField) {
        self.tagsTextField.text = [self.tagsTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    else {
        [self.tagsTextField becomeFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagsTextField) {
        if ([string isEqualToString:@" "]) {
            if ([textField.text length] == 0) {
                return NO;
            }
            else if ([textField.text hasSuffix:@" "]) {
                return NO;
            }
            else {
                NSMutableString *mutableTags = [NSMutableString stringWithString:textField.text];
                NSInteger numberOfSpaces = [mutableTags replaceOccurrencesOfString:@" " withString:@"." options:NSLiteralSearch range:NSMakeRange(0, mutableTags.length)];
                if (numberOfSpaces > 2) {
                    return NO;
                }
            }
        }
    }
    else {
        if ([string isEqualToString:@" "]) {
            return NO;
        }
    }
    return YES;
}

- (void)closeButtonTouchUpInside:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addButtonTouchUpInside:(id)sender {
    NSMutableArray *components = [NSMutableArray array];
    NSString *username = self.userTextField.text;
    if (username && username.length > 0) {
        [components addObject:[NSString stringWithFormat:@"u:%@", username]];
    }
    
    NSString *fromSuffix;
    
    NSString *tags = self.tagsTextField.text;
    if (tags && tags.length > 0) {
        for (NSString *tag in [tags componentsSeparatedByString:@" "]) {
            if (tag.length > 0) {
                if ([tag hasPrefix:@"from:"]) {
                    fromSuffix = tag;
                }
                else {
                    [components addObject:[NSString stringWithFormat:@"t:%@", tag]];
                }
            }
        }
    }

    if (fromSuffix) {
        [components addObject:fromSuffix];
    }
    
    if (components.count > 0) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.tagsTextField.enabled = NO;
        self.userTextField.enabled = NO;
        PinboardFeedDataSource *dataSource = [[PinboardFeedDataSource alloc] initWithComponents:components];
        [dataSource addDataSource:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.modalDelegate closeModal:self];
            });
        }];
    }
}

@end

//
//  PPAddSavedFeedViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/30/13.
//
//

#import "PPAddSavedFeedViewController.h"
#import "PPGroupedTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "PinboardFeedDataSource.h"
#import "NSString+URLEncoding2.h"

@interface PPAddSavedFeedViewController ()

@end

@implementation PPAddSavedFeedViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self.modalDelegate action:@selector(closeModal:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTouchUpInside:)];
        
        UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:16];
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
        self.tagsTextField.placeholder = NSLocalizedString(@"Tags, separated by spaces", nil);
        self.tagsTextField.returnKeyType = UIReturnKeyDone;
        self.tagsTextField.text = @"";
        
        self.title = NSLocalizedString(@"Add Feed", nil);
    }
    return self;
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
    static NSString *CellIdentifier = @"Cell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackground];
    if (indexPath.row == 1) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayer]];
    }
    
    if (indexPath.row == 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayer]];
    }
    
    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    CGRect frame = cell.frame;
    if (indexPath.row == 0) {
        cell.imageView.image = [UIImage imageNamed:@"user"];
        self.userTextField.frame = CGRectMake((frame.size.width - 240) / 2.0, (frame.size.height - 31) / 2.0, 240, 31);
        [cell.contentView addSubview:self.userTextField];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"tag"];
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
        [self addButtonTouchUpInside:nil];
    }
    else {
        [self.tagsTextField becomeFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagsTextField) {
        if ([string isEqualToString:@" "]) {
            NSMutableString *mutableTags = [NSMutableString stringWithString:textField.text];
            NSInteger numberOfSpaces = [mutableTags replaceOccurrencesOfString:@" " withString:@"." options:NSLiteralSearch range:NSMakeRange(0, mutableTags.length)];
            if (numberOfSpaces > 2) {
                return NO;
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

- (void)addButtonTouchUpInside:(id)sender {
    NSMutableArray *components = [NSMutableArray array];
    NSString *username = self.userTextField.text;
    if (username && username.length > 0) {
        [components addObject:[NSString stringWithFormat:@"u:%@", username]];
    }
    
    NSString *tags = self.tagsTextField.text;
    if (tags && tags.length > 0) {
        for (NSString *tag in [tags componentsSeparatedByString:@" "]) {
            if (tag.length > 0) {
                [components addObject:[NSString stringWithFormat:@"t:%@", tag]];
            }
        }
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

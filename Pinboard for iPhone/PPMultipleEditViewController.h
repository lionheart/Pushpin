//
//  PPMultipleEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import "PPTableViewController.h"

@interface PPMultipleEditViewController : PPTableViewController <UITextFieldDelegate>

@property (nonatomic, retain) UITextField *tagsToAddTextField;
@property (nonatomic, retain) UITextField *tagsToRemoveTextField;

@property (nonatomic, retain) NSMutableArray *tagsToAddCompletions;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic) BOOL autocompleteInProgress;

- (void)tagsToAddTextFieldUpdatedWithRange:(NSRange)range andString:(NSString *)string;

@end

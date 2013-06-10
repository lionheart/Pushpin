//
//  PPMultipleEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import "PPTableViewController.h"

@interface PPMultipleEditViewController : PPTableViewController <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *tagsToAddTextField;
@property (nonatomic, strong) UITextField *tagsToRemoveTextField;

@property (nonatomic, strong) NSMutableArray *tagsToAddCompletions;
@property (nonatomic, strong) NSMutableArray *tagsToRemoveCompletions;
@property (nonatomic, strong) NSMutableArray *existingTags;
@property (nonatomic, strong) NSMutableDictionary *tagCounts;
@property (nonatomic) BOOL autocompleteInProgress;

- (void)tagsToAddTextFieldUpdatedWithRange:(NSRange)range andString:(NSString *)string;
- (void)tagsToRemoveTextFieldUpdatedWithRange:(NSRange)range andString:(NSString *)string;

@end

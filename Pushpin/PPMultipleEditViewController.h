//
//  PPMultipleEditViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 6/9/13.
//
//

#import "PPTagEditViewController.h"

typedef NS_ENUM(NSInteger, PPMultipleEditSectionType) {
    PPMultipleEditSectionAddedTags,
    PPMultipleEditSectionExistingTags,
    PPMultipleEditSectionOtherData
};

typedef NS_ENUM(NSInteger, PPMultipleEditSectionOtherRowType) {
    PPMultipleEditSectionOtherRowPrivate,
    PPMultipleEditSectionOtherRowRead
};

enum : NSInteger {
    PPMultipleEditSectionCount = PPMultipleEditSectionOtherData + 1,
};

@interface PPMultipleEditViewController : UIViewController <UITextFieldDelegate, PPTagEditing, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITextField *tagsToAddTextField;

@property (nonatomic, strong) NSArray *bookmarks;
@property (nonatomic, strong) NSMutableArray *existingTags;
@property (nonatomic, strong) NSMutableOrderedSet *tagsToRemove;
@property (nonatomic, strong) NSMutableArray *tagsToAdd;

- (id)initWithBookmarks:(NSArray *)bookmarks;

@end

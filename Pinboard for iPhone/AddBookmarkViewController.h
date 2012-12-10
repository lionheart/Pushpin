//
//  AddBookmarkViewController.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/14/12.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"


@interface AddBookmarkViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, retain) id<ModalDelegate> modalDelegate;
@property (nonatomic, retain) id<BookmarkUpdatedDelegate> bookmarkUpdateDelegate;
@property (nonatomic, retain) UITextField *urlTextField;
@property (nonatomic, retain) UITextField *descriptionTextField;
@property (nonatomic, retain) UITextField *titleTextField;
@property (nonatomic, retain) UISwitch *privateSwitch;
@property (nonatomic, retain) UISwitch *readSwitch;
@property (nonatomic, retain) UITextField *tagTextField;

@property (nonatomic, retain) NSNumber *setAsPrivate;
@property (nonatomic, retain) NSNumber *markAsRead;

- (void)privateSwitchChanged:(id)sender;
- (void)readSwitchChanged:(id)sender;
- (void)addBookmark;
- (void)close;

@end

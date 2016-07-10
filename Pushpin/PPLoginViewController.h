//
//  PPLoginViewController.h
//  Pushpin
//
//  Created by Eric Olszewski on 6/26/15.
//  Copyright (c) 2015 Lionheart Software. All rights reserved.
//

@import UIKit;
@import LHSKeyboardAdjusting;

#warning Rename these typedefs! Best to use Xcode's refactor / rename tool.

typedef NS_ENUM(NSInteger, PPLoginServiceRowType) {
    PPLoginPinboardRow,
    PPLoginPushpinRow
};

@interface PPLoginViewController : UIViewController <LHSKeyboardAdjusting, UITableViewDataSource, UITableViewDelegate>

@end

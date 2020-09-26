//
//  PPNoteViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 7/5/14.
//
//

@import LHSCategoryCollection;
@import ASPinboard;

#import "PPNoteViewController.h"

@implementation PPNoteViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
    ASPinboard *pinboard = [ASPinboard sharedInstance];
    [pinboard noteWithId:self.noteID
                 success:^(NSString *title, NSString *text) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         self.text = text;

                         [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                     });
                 }];
}

@end

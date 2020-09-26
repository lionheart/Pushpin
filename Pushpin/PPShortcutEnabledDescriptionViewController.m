//
//  PPEditDescriptionViewController_iPad.m
//  Pushpin
//
//  Created by Dan Loewenherz on 7/3/14.
//
//

#import "PPShortcutEnabledDescriptionViewController.h"

@interface PPShortcutEnabledDescriptionViewController ()

@property (nonatomic, strong) UIKeyCommand *goBackKeyCommand;

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand;

@end

@implementation PPShortcutEnabledDescriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.goBackKeyCommand = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(handleKeyCommand:)];
}

#pragma mark - Key Commands

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
    return @[self.goBackKeyCommand];
}

- (void)handleKeyCommand:(UIKeyCommand *)keyCommand {
    if (keyCommand == self.goBackKeyCommand) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end


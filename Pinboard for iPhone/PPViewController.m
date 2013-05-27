//
//  PPViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/27/13.
//
//

#import "PPViewController.h"

@interface PPViewController ()

@end

@implementation PPViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"X" style:UIBarButtonItemStylePlain target:nil action:nil];
}

@end

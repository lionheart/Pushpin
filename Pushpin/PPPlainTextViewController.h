//
//  PPLicenseViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/11/14.
//
//

@import UIKit;

@interface PPPlainTextViewController : UIViewController

@property (nonatomic, strong) NSString *text;

+ (instancetype)plainTextViewControllerWithString:(NSString *)text;

@end

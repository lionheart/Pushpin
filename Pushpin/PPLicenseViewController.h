//
//  PPLicenseViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/11/14.
//
//

@import UIKit;

@interface PPLicenseViewController : UIViewController

@property (nonatomic, strong) NSString *text;

+ (instancetype)licenseViewControllerWithLicense:(NSString *)license;

@end

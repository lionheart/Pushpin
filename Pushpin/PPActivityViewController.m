//
//  PPActivityViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/19/14.
//
//

#import "PPActivityViewController.h"
#import "PPConstants.h"
#import "PPAppDelegate.h"
#import "PPBrowserActivity.h"
#import "PPMobilizerUtility.h"
#import "PPSettings.h"

@interface PPActivityViewController ()

@end

@implementation PPActivityViewController

- (instancetype)initWithActivityItems:(NSArray *)activityItems {
    PPMobilizerUtility *utility = [PPMobilizerUtility sharedInstance];

    NSMutableArray *browserActivites = [NSMutableArray array];
    PPBrowserActivity *browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"http" browser:@"Safari"];

    NSURL *url = activityItems[1];
    [browserActivity setUrlString:[utility originalURLStringForURL:url]];
    [browserActivites addObject:browserActivity];

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"icabmobile://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"icabmobile" browser:@"iCab Mobile"];
        [browserActivites addObject:browserActivity];
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"googlechrome" browser:@"Chrome"];
        [browserActivites addObject:browserActivity];
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ohttp://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"ohttp" browser:@"Opera"];
        [browserActivites addObject:browserActivity];
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dolphin://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"dolphin" browser:@"Dolphin"];
        [browserActivites addObject:browserActivity];
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cyber://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"cyber" browser:@"Cyberspace"];
        [browserActivites addObject:browserActivity];
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"firefox://"]]) {
        browserActivity = [[PPBrowserActivity alloc] initWithUrlScheme:@"firefox" browser:@"Firefox"];
        [browserActivites addObject:browserActivity];
    }

    self = [super initWithActivityItems:activityItems applicationActivities:browserActivites];
    if (self) {
        self.excludedActivityTypes = @[UIActivityTypePostToWeibo,
                                       UIActivityTypeAssignToContact,
                                       UIActivityTypePostToVimeo];
    }
    return self;
}

- (UIActivityViewControllerCompletionHandler)completionHandler {
    return ^(NSString *activityType, BOOL completed) {
    };
}

@end

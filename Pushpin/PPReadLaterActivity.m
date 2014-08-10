//
//  PPReadLaterActivity.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

#import <SafariServices/SafariServices.h>

#import "PPAppDelegate.h"
#import "PPReadLaterActivity.h"
#import "PPWebViewController.h"
#import "PPSettings.h"

#import <PocketAPI/PocketAPI.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface PPReadLaterActivity ()

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *url;

@end

@implementation PPReadLaterActivity

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
            self.url = (NSURL *)item;
        }
        else if ([item isKindOfClass:[NSString class]]) {
            self.title = (NSString *)item;
        }
    }
}

- (id)initWithService:(PPReadLaterType)type {
    if (self = [super init]) {
        self.service = type;

        switch (self.service) {
            case PPReadLaterInstapaper:
                self.serviceName = NSLocalizedString(@"Instapaper", nil);
                break;
                
            case PPReadLaterReadability:
                self.serviceName = NSLocalizedString(@"Readability", nil);
                break;
                
            case PPReadLaterNative:
                self.serviceName = @"readinglist";
                break;

            case PPReadLaterPocket:
                self.serviceName = NSLocalizedString(@"Pocket", nil);
                break;
                
            default:
                break;
        }
    }
    
    return self;
}

- (NSString *)activityTitle {
    if (self.service == PPReadLaterNative) {
        return NSLocalizedString(@"Add to Reading List", nil);
    }

    return [NSString stringWithFormat:@"Save to %@", self.serviceName];
}

- (NSString *)activityType {
    switch (self.service) {
        case PPReadLaterInstapaper:
            return PPInstapaperActivity;

        case PPReadLaterReadability:
            return PPReadabilityActivity;

        case PPReadLaterNative:
            return PPReadingListActivity;

        case PPReadLaterPocket:
            return PPPocketActivity;

        case PPReadLaterNone:
            return PPNoActivity;
    }
}

- (UIImage *)activityImage {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"activity-%@", [self.serviceName lowercaseString]]];
    return image;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
            return YES;
        }
    }

    return NO;
}

- (void)performActivity {
    [PPUtilities shareToReadLater:self.service
                              URL:self.url.absoluteString
                            title:self.title
                            delay:0.5
                       completion:^{
                           [self activityDidFinish:YES];
                       }];
}

@end
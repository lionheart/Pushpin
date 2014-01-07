//
//  PPReadLaterActivity.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

#import "AppDelegate.h"
#import "PPReadLaterActivity.h"
#import "PPWebViewController.h"

@implementation PPReadLaterActivity

@synthesize service, serviceName;

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
    return @"PPReadLaterActivity";
}

- (UIImage *)activityImage {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"activity-%@", [self.serviceName lowercaseString]]];
    return image;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {
    if ([self.delegate respondsToSelector:@selector(sendToReadLater:)]) {
        [self.delegate performSelector:@selector(sendToReadLater:) withObject:@(self.service)];
    }
}

@end
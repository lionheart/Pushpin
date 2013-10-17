//
//  PPReadLaterActivity.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

#import "PPReadLaterActivity.h"
#import "AppDelegate.h"
#import "PPWebViewController.h"

@implementation PPReadLaterActivity

@synthesize service, serviceName;

- (id)initWithService:(NSUInteger)type {
    if (self = [super init]) {
        self.service = type;
        if (type == READLATER_INSTAPAPER) {
            self.serviceName = NSLocalizedString(@"Instapaper", nil);
        } else if (type == READLATER_POCKET) {
            self.serviceName = NSLocalizedString(@"Pocket", nil);
        } else if (type == READLATER_READABILITY) {
            self.serviceName = NSLocalizedString(@"Readability", nil);
        } else if (type == READLATER_NATIVE) {
            self.serviceName = @"readinglist";
        }
    }
    
    return self;
}

- (NSString *)activityTitle {
    if (self.service == READLATER_NATIVE) {
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
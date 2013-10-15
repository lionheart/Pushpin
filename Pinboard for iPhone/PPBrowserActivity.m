//
//  PPBrowserActivity.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

#import "PPBrowserActivity.h"
#import "NSString+URLEncoding2.h"

@implementation PPBrowserActivity

@synthesize browserName;
@synthesize urlScheme;
@synthesize urlString;

- (id)initWithUrlScheme:(NSString *)scheme {
    if (self = [super init]) {
        self.urlScheme = scheme;
    }
    
    return self;
}

- (id)initWithUrlScheme:(NSString *)scheme browser:(NSString *)browser {
    if (self = [self initWithUrlScheme:scheme]) {
        self.browserName = browser;
    }
    
    return self;
}

- (id)initWithUrlScheme:(NSString *)scheme url:(NSString *)url browser:(NSString *)browser {
    if (self = [self initWithUrlScheme:scheme]) {
        self.urlString = url;
        self.browserName = browser;
    }
    
    return self;
}

- (NSString *)activityTitle {
    return [NSString stringWithFormat:@"Open in %@", self.browserName];
}

- (NSString *)activityType {
    return @"PPBrowserActivity";
}

- (UIImage *)activityImage {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"activity-browser-%@", [self.browserName lowercaseString]]];
    if (!image) {
        image = [UIImage imageNamed:@"activity-browser-safari"];
    }
    return image;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {
    NSString *tempUrl = self.urlString;
    NSURL *url = [NSURL URLWithString:tempUrl];
    NSRange range = [tempUrl rangeOfString:self.urlScheme];
    if ([self.browserName isEqualToString:NSLocalizedString(@"Chrome", nil)]) {
        url = [NSURL URLWithString:[tempUrl stringByReplacingCharactersInRange:range withString:@"googlechrome"]];
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=pushpin%%3A%%2F%%2F&&x-source=Pushpin", [tempUrl urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
        } else {
            url = [NSURL URLWithString:[tempUrl stringByReplacingCharactersInRange:range withString:@"googlechrome"]];
        }
    } else if ([self.browserName isEqualToString:NSLocalizedString(@"Opera", nil)]) {
        url = [NSURL URLWithString:[tempUrl stringByReplacingCharactersInRange:range withString:@"ohttp"]];
    } else if ([self.browserName isEqualToString:NSLocalizedString(@"Dolphin", nil)]) {
        url = [NSURL URLWithString:[tempUrl stringByReplacingCharactersInRange:range withString:@"dolphin"]];
    } else if ([self.browserName isEqualToString:NSLocalizedString(@"Cyberspace", nil)]) {
        url = [NSURL URLWithString:[tempUrl stringByReplacingCharactersInRange:range withString:@"cyber"]];
    } else if ([self.browserName isEqualToString:NSLocalizedString(@"iCab Mobile", nil)]) {
        url = [NSURL URLWithString:[tempUrl stringByReplacingCharactersInRange:range withString:@"icabmobile"]];
    }
    
    [[UIApplication sharedApplication] openURL:url];
}

@end

//
//  PPBrowserActivity.m
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

@import OpenInChrome;

#import "PPBrowserActivity.h"
#import "NSString+URLEncoding2.h"

@interface PPBrowserActivity ()

@property (nonatomic, strong) NSURL *url;

@end

@implementation PPBrowserActivity

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
            self.url = (NSURL *)item;
            break;
        }
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
            return YES;
        }
    }

    return NO;
}

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

- (void)performActivity {
    if ([self.browserName isEqualToString:NSLocalizedString(@"Chrome", nil)]) {
        OpenInChromeController *openInChromeController = [OpenInChromeController sharedInstance];
        [openInChromeController openInChrome:self.url withCallbackURL:[NSURL URLWithString:@"pushpin://"] createNewTab:YES];
    } else if ([self.browserName isEqualToString:NSLocalizedString(@"Firefox", nil)]) {
        NSString *urlString = [NSString stringWithFormat:@"firefox://open-url?url=%@", encodeByAddingPercentEscapes(self.url.absoluteString)];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    } else {
        NSRange range = [self.url.absoluteString rangeOfString:@"http"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self.url.absoluteString stringByReplacingCharactersInRange:range withString:self.urlScheme]] options:@{} completionHandler:nil];;
    }

    [self activityDidFinish:YES];
}

@end

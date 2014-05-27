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

#import <PocketAPI/PocketAPI.h>
#import <KeychainItemWrapper/KeychainItemWrapper.h>
#import <oauthconsumer/OAuthConsumer.h>

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
    CGFloat delay = 0.5;

    switch (self.service) {
        case PPReadLaterInstapaper: {
            PPAppDelegate *delegate = [PPAppDelegate sharedDelegate];

            NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1.1/bookmarks/add"]];
            OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
            OAToken *token = delegate.instapaperToken;
            
            if (token) {
                OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
                [request setHTTPMethod:@"POST"];
                NSMutableArray *parameters = [[NSMutableArray alloc] init];
                [parameters addObject:[OARequestParameter requestParameter:@"title" value:self.title]];
                [parameters addObject:[OARequestParameter requestParameter:@"url" value:self.url.absoluteString]];
                [request setParameters:parameters];
                [request prepare];
                
                [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
                [NSURLConnection sendAsynchronousRequest:request
                                                   queue:[NSOperationQueue mainQueue]
                                       completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                           [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
                                           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                           
                                           UILocalNotification *notification = [[UILocalNotification alloc] init];
                                           notification.alertAction = @"Open Pushpin";
                                           if (httpResponse.statusCode == 200) {
                                               notification.alertBody = NSLocalizedString(@"Sent to Instapaper.", nil);
                                               notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                               [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                           }
                                           else if (httpResponse.statusCode == 1221) {
                                               notification.alertBody = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                               notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                           }
                                           else {
                                               notification.alertBody = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                               notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                           }
                                           
                                           [self activityDidFinish:YES];
                                           
                                           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                               [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                           });
                                       }];
            }
            else {
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.alertBody = NSLocalizedString(@"Instapaper credentials have expired. Please re-authenticate and try again.", nil);
                notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            }
            break;
        }

        case PPReadLaterReadability: {
            KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"ReadabilityOAuth" accessGroup:nil];
            NSString *resourceKey = [keychain objectForKey:(__bridge id)kSecAttrAccount];
            NSString *resourceSecret = [keychain objectForKey:(__bridge id)kSecValueData];
            NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.readability.com/api/rest/v1/bookmarks"]];
            OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
            OAToken *token = [[OAToken alloc] initWithKey:resourceKey secret:resourceSecret];
            OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint consumer:consumer token:token realm:nil signatureProvider:nil];
            [request setHTTPMethod:@"POST"];
            [request setParameters:@[[OARequestParameter requestParameter:@"url" value:self.url.absoluteString]]];
            [request prepare];

            [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];;
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];;
                                       UILocalNotification *notification = [[UILocalNotification alloc] init];
                                       notification.alertAction = @"Open Pushpin";

                                       NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                       if (httpResponse.statusCode == 202) {
                                           notification.alertBody = @"Sent to Readability.";
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                       }
                                       else if (httpResponse.statusCode == 409) {
                                           notification.alertBody = @"Link already sent to Readability.";
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }
                                       else {
                                           notification.alertBody = @"Error sending to Readability.";
                                           notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
                                       }

                                       [self activityDidFinish:YES];

                                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                           [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                       });
                                   }];
            break;
        }

        case PPReadLaterPocket: {
            [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:self.url.absoluteString]
                                 withTitle:self.title
                                   handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                       [self activityDidFinish:YES];

                                       if (!error) {
                                           UILocalNotification *notification = [[UILocalNotification alloc] init];
                                           notification.alertBody = @"Sent to Pocket.";
                                           notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
                                           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                               [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                           });

                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                       }
                                   }];
            break;
        }

        case PPReadLaterNative: {
            [self activityDidFinish:YES];

            UILocalNotification *notification = [[UILocalNotification alloc] init];

            // Add to the native Reading List
            NSError *error;
            [[SSReadingList defaultReadingList] addReadingListItemWithURL:self.url
                                                                    title:self.title
                                                              previewText:nil
                                                                    error:&error];
            if (error) {
                notification.alertBody = @"Error adding to Reading List";
                notification.userInfo = @{@"success": @(NO), @"updated": @(NO)};
            }
            else {
                notification.alertBody = @"Added to Reading List";
                notification.userInfo = @{@"success": @(YES), @"updated": @(NO)};
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            });
            [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Native Reading List"}];
            break;
        }

        case PPReadLaterNone: {
            [self activityDidFinish:YES];
            break;
        }
    }
}

@end
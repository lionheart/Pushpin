//
//  PPConstants.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/5/14.
//
//

#import "PPConstants.h"
#import <oauthconsumer/OAuthConsumer.h>

@implementation PPConstants

+ (OAConsumer *)readabilityConsumer {
    return [[OAConsumer alloc] initWithKey:kReadabilityKey secret:kReadabilitySecret];
}

+ (OAConsumer *)instapaperConsumer {
    return [[OAConsumer alloc] initWithKey:kInstapaperKey secret:kInstapaperSecret];
}

@end

//
//  PPConstants.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/5/14.
//
//

#import <Foundation/Foundation.h>

static NSString *emptyString = @"";
static NSString *newLine = @"\n";
static NSString *ellipsis = @"…";

static const NSString *PPBadgeFontSize = @"fontSize";
static const NSString *PPBadgeNormalBackgroundColor = @"normalBackgroundColor";
static const NSString *PPBadgeActiveBackgroundColor = @"activeBackgroundColor";
static const NSString *PPBadgeDisabledBackgroundColor = @"disabledBackgroundColor";
static const NSString *PPBadgeFontColor = @"fontColor";

typedef enum : NSInteger {
    PPPersonalFeedAll,
    PPPersonalFeedPrivate,
    PPPersonalFeedPublic,
    PPPersonalFeedUnread,
    PPPersonalFeedUntagged,
    PPPersonalFeedStarred
} PPPersonalFeedType;

typedef enum : NSInteger {
    PPCommunityFeedNetwork,
    PPCommunityFeedPopular,
    PPCommunityFeedWikipedia,
    PPCommunityFeedFandom,
    PPCommunityFeedJapan
} PPCommunityFeedType;

static NSArray *PPPersonalFeeds() {
    return @[@"all", @"private", @"public", @"unread", @"untagged", @"starred"];
}

static NSArray *PPCommunityFeeds() {
    return @[@"network", @"popular", @"wikipedia", @"fandom", @"japan"];
}

@interface PPConstants : NSObject

@end

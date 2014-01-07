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

typedef enum : NSInteger {
    PPPostSourceTwitter,
    PPPostSourceTwitterFave,
    PPPostSourceReadability,
    PPPostSourceDelicious,
    PPPostSourcePocket, // AKA Read It Later
    PPPostSourceInstapaper,
    PPPostSourceEmail,
} PPPostSourceType;

typedef enum : NSInteger {
    PPPostActionCopyToMine,
    PPPostActionCopyURL,
    PPPostActionDelete,
    PPPostActionEdit,
    PPPostActionReadLater,
    PPPostActionMarkAsRead
} PPPostActionType;

typedef enum : NSInteger {
    PPSearchAllField,
    PPSearchFullText,
    PPSearchTitles,
    PPSearchDescriptions,
    PPSearchTags,
} PPSearchType;

typedef enum : NSInteger {
    PPBrowserWebview,
    PPBrowserSafari,
    PPBrowserChrome,
    PPBrowseriCabMobile,
    PPBrowserDolphin,
    PPBrowserCyberspace,
    PPBrowserOpera
} PPBrowserType;

typedef enum : NSInteger {
    PPReadLaterNone,
    PPReadLaterInstapaper,
    PPReadLaterReadability,
    PPReadLaterPocket,
    PPReadLaterNative
} PPReadLaterType;

typedef enum : NSInteger {
    PPBookmarkEventAdd,
    PPBookmarkEventUpdate,
    PPBookmarkEventDelete
} PPBookmarkEventType;

typedef enum : NSInteger {
    kPinboardFilterFalse = 0,
    kPinboardFilterTrue = 1,
    kPinboardFilterNone
} kPinboardFilterType;

static NSArray *PPPersonalFeeds() {
    return @[@"all", @"private", @"public", @"unread", @"untagged", @"starred"];
}

static NSArray *PPCommunityFeeds() {
    return @[@"network", @"popular", @"wikipedia", @"fandom", @"japan"];
}

@interface PPConstants : NSObject

@end

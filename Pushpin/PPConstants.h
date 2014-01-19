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

static NSString *PPBookmarkDisplaySettingUpdated = @"PPBookmarkDisplaySetting";
static NSString *PPBookmarkCompressSettingUpdate = @"PPBookmarkCompressSetting";

typedef enum : NSInteger {
    PPMobilizerGoogle,
    PPMobilizerInstapaper,
    PPMobilizerReadability
} PPMobilizerType;

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
    PPPostActionCopyToMine = 1 << 0,
    PPPostActionCopyURL = 1 << 1,
    PPPostActionDelete = 1 << 2,
    PPPostActionEdit = 1 << 3,
    PPPostActionReadLater = 1 << 4,
    PPPostActionMarkAsRead = 1 << 5,
    PPPostActionShare = 1 << 6
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

static dispatch_queue_t PPSerialQueue() {
    return dispatch_queue_create("Pushpin Serial Queue", DISPATCH_QUEUE_SERIAL);
}

static NSArray *PPPersonalFeeds() {
    return @[@"all", @"private", @"public", @"unread", @"untagged", @"starred"];
}

static NSArray *PPCommunityFeeds() {
    return @[@"network", @"popular", @"wikipedia", @"fandom", @"japan"];
}

@interface PPConstants : NSObject

@end

//
//  PPConstants.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/5/14.
//
//

@import Foundation;

typedef enum : NSInteger {
    PPMobilizerGoogle,
    PPMobilizerInstapaper,
    PPMobilizerReadability
} PPMobilizerType;

typedef enum PPProviders : NSInteger {
    PPProviderPinboard,
    PPProviderDelicious
} PPProviderType;

#ifdef DELICIOUS
typedef enum : NSInteger {
    PPDeliciousPersonalFeedAll,
    PPDeliciousPersonalFeedPrivate,
    PPDeliciousPersonalFeedPublic,
    PPDeliciousPersonalFeedUnread,
    PPDeliciousPersonalFeedUntagged
} PPDeliciousPersonalFeedType;

typedef enum : NSInteger {
    PPDeliciousSectionPersonal,
} PPDeliciousSectionType;

static NSInteger PPProviderDeliciousSections = PPDeliciousSectionPersonal + 1;

typedef enum : NSInteger {
    PPDeliciousPersonalRows = PPDeliciousPersonalFeedUntagged + 1,
} PPDeliciousRowCounts;
#endif

#ifdef PINBOARD
typedef enum : NSInteger {
    PPPinboardPersonalFeedAll,
    PPPinboardPersonalFeedPrivate,
    PPPinboardPersonalFeedPublic,
    PPPinboardPersonalFeedUnread,
    PPPinboardPersonalFeedUntagged,
    PPPinboardPersonalFeedStarred
} PPPinboardPersonalFeedType;

typedef enum : NSInteger {
    PPPinboardCommunityFeedNetwork,
    PPPinboardCommunityFeedPopular,
    PPPinboardCommunityFeedWikipedia,
    PPPinboardCommunityFeedFandom,
    PPPinboardCommunityFeedJapan
} PPPinboardCommunityFeedType;

typedef enum : NSInteger {
    PPPinboardSectionPersonal,
    PPPinboardSectionCommunity,
    PPPinboardSectionSavedFeeds
} PPPinboardSectionType;

typedef enum : NSInteger {
    PPPinboardPersonalRows = PPPinboardPersonalFeedStarred + 1,
    PPPinboardCommunityRows = PPPinboardCommunityFeedJapan + 1
} PPPinboardRowCounts;

static NSInteger PPProviderPinboardSections = PPPinboardSectionSavedFeeds + 1;
#endif

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
    kPushpinFilterFalse = 0,
    kPushpinFilterTrue = 1,
    kPushpinFilterNone
} kPushpinFilterType;

static dispatch_queue_t PPSerialQueue() {
    return dispatch_queue_create("Pushpin Serial Queue", DISPATCH_QUEUE_SERIAL);
}

static NSString *emptyString = @"";
static NSString *newLine = @"\n";
static NSString *ellipsis = @"…";

static NSString *PPBadgeFontSize = @"fontSize";
static NSString *PPBadgeNormalBackgroundColor = @"normalBackgroundColor";
static NSString *PPBadgeActiveBackgroundColor = @"activeBackgroundColor";
static NSString *PPBadgeDisabledBackgroundColor = @"disabledBackgroundColor";
static NSString *PPBadgeFontColor = @"fontColor";

static NSString *PPBookmarkDisplaySettingUpdated = @"PPBookmarkDisplaySetting";
static NSString *PPBookmarkCompressSettingUpdate = @"PPBookmarkCompressSetting";

static NSString *PPInstapaperActivity = @"PPInstapaperActivity";
static NSString *PPReadabilityActivity = @"PPReadabilityActivity";
static NSString *PPReadingListActivity = @"PPReadingListActivity";
static NSString *PPPocketActivity = @"PPPocketActivity";
static NSString *PPNoActivity = @"PPNoActivity";

#ifdef DELICIOUS
static NSString *PPTestFlightToken = @"da69c1e2-d02e-4e26-9e8b-189503ae410b";
static NSString *PPMixpanelToken = @"c9c119f24aa8b5d17311be35ecf2310e";
static NSString *PPPocketIPhoneToken = @"23110-401de8502cbf573a2e115c2a";
static NSString *PPPocketIPadToken = @"23110-86247a432b99945a85a44846";
static PPProviderType PPProvider __unused = PPProviderDelicious;

static NSArray *PPSections() {
    return @[@"personal", @"community", @"feeds"];
}

static NSArray *PPPersonalFeeds() {
    return @[@"all", @"private", @"public", @"unread", @"untagged"];
}

static NSArray *PPCommunityFeeds() {
    return @[];
}
#endif

#ifdef PINBOARD
static NSString *PPTestFlightToken = @"575d650a-43d5-4e99-a3bb-2b7bbae29a6c";
static NSString *PPMixpanelToken = @"045e859e70632363c4809784b13c5e98";
static NSString *PPPocketIPhoneToken = @"11122-03068da9a8951bec2dcc93f3";
static NSString *PPPocketIPadToken = @"11122-03068da9a8951bec2dcc93f3";
static PPProviderType PPProvider __unused = PPProviderDelicious;

static NSArray *PPSections() {
    return @[@"personal", @"community", @"feeds"];
}

static NSArray *PPPersonalFeeds() {
    return @[@"all", @"private", @"public", @"unread", @"untagged", @"starred"];
}

static NSArray *PPCommunityFeeds() {
    return @[@"network", @"popular", @"wikipedia", @"fandom", @"japan"];
}
#endif

@interface PPConstants : NSObject

@end

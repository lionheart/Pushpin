//
//  PPConstants.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/5/14.
//
//

@import Foundation;

@class OAConsumer;

typedef void (^PPErrorBlock)(NSError *error);

typedef enum : NSInteger {
    PPMobilizerGoogle,
    PPMobilizerInstapaper,
    PPMobilizerReadability
} PPMobilizerType;

typedef enum PPProviders : NSInteger {
    PPProviderPinboard,
    PPProviderDelicious
} PPProviderType;

static NSString *PPTwitterUsername = @"Pushpin_app";

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
    PPPinboardCommunityFeedJapan,
    PPPinboardCommunityFeedRecent
} PPPinboardCommunityFeedType;

typedef enum : NSInteger {
    PPPinboardSectionPersonal,
    PPPinboardSectionCommunity,
    PPPinboardSectionSavedFeeds,
    PPPinboardSectionSearches
} PPPinboardSectionType;

typedef enum : NSInteger {
    PPPinboardPersonalRows = PPPinboardPersonalFeedStarred + 1,
    PPPinboardCommunityRows = PPPinboardCommunityFeedRecent + 1
} PPPinboardRowCounts;

static NSInteger PPProviderPinboardSections = PPPinboardSectionSearches + 1;

typedef NS_ENUM(NSInteger, PPOfflineFetchCriteriaType) {
    PPOfflineFetchCriteriaUnread,
    PPOfflineFetchCriteriaRecent,
    PPOfflineFetchCriteriaUnreadAndRecent,
    PPOfflineFetchCriteriaEverything
};

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
    PPPostActionReadLaterUnused = 1 << 4,
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
    PPBrowserOpera,
    PPBrowserSafariViewController
} PPBrowserType;

typedef enum : NSInteger {
    PPReadLaterNone,
    PPReadLaterInstapaper,
    PPReadLaterReadability,
    PPReadLaterPocket,
    PPReadLaterNative
} PPReadLaterType;

typedef enum : NSInteger {
    PPFontAdjustmentSmallest,
    PPFontAdjustmentSmall,
    PPFontAdjustmentMedium,
    PPFontAdjustmentBig,
    PPFontAdjustmentBiggest
} PPFontAdjustmentType;

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

static NSString *PPErrorDomain = @"PPErrorDomain";

static NSString *emptyString = @"";
static NSString *newLine = @"\n";
static NSString *ellipsis = @"…";

static NSString *PPBadgeFontSize = @"fontSize";
static NSString *PPBadgeNormalBackgroundColor = @"normalBackgroundColor";
static NSString *PPBadgeActiveBackgroundColor = @"activeBackgroundColor";
static NSString *PPBadgeDisabledBackgroundColor = @"disabledBackgroundColor";
static NSString *PPBadgeFontColor = @"fontColor";
static NSString *PPBadgeFontName = @"fontName";

static NSString *PPBookmarkDisplaySettingUpdated = @"PPBookmarkDisplaySetting";
static NSString *PPBookmarkCompressSettingUpdate = @"PPBookmarkCompressSetting";

static NSString *PPInstapaperActivity = @"PPInstapaperActivity";
static NSString *PPReadabilityActivity = @"PPReadabilityActivity";
static NSString *PPReadingListActivity = @"PPReadingListActivity";
static NSString *PPPocketActivity = @"PPPocketActivity";
static NSString *PPNoActivity = @"PPNoActivity";

// Notification Names
static NSString *const PPBookmarkEventNotificationName = @"PPBookmarkUpdateNotificationName";

static NSArray *PPFontAdjustmentTypes() {
    return @[@"Smallest", @"Small", @"Medium", @"Big", @"Biggest"];
}

static NSArray *PPOfflineFetchCriterias() {
    return @[@"Unread", @"Recent", @"Unread and Recent", @"Everything"];
}



static NSString *PPTestFlightToken = @"575d650a-43d5-4e99-a3bb-2b7bbae29a6c";
static NSString *PPMixpanelToken = @"045e859e70632363c4809784b13c5e98";
static NSString *PPPocketIPhoneToken = @"11122-03068da9a8951bec2dcc93f3";
static NSString *PPPocketIPadToken = @"11122-03068da9a8951bec2dcc93f3";
static PPProviderType PPProvider __unused = PPProviderPinboard;

static NSArray *PPSections() {
    return @[@"personal", @"community", @"feeds"];
}

static NSArray *PPPersonalFeeds() {
    return @[@"all", @"private", @"public", @"unread", @"untagged", @"starred"];
}

static NSArray *PPCommunityFeeds() {
    static dispatch_once_t onceToken;
    static NSArray *feeds;
    dispatch_once(&onceToken, ^{
        feeds = @[@"network", @"popular", @"wikipedia", @"fandom", @"japanese", @"recent"];
    });
    return feeds;
}

@interface PPConstants : NSObject

@end

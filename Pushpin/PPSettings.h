//
//  PPSettings.h
//  Pushpin
//
//  Created by Dan Loewenherz on 8/10/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPConstants.h"
#import "PPReaderSettings.h"

@interface PPSettings : NSObject

@property (nonatomic) PPBrowserType browser;
@property (nonatomic) PPMobilizerType mobilizer;
@property (nonatomic) PPReadLaterType readLater;
@property (nonatomic) PPFontAdjustmentType fontAdjustment;
@property (nonatomic) PPOfflineFetchCriteriaType offlineFetchCriteria;
@property (nonatomic, strong) PPReaderSettings *readerSettings;

@property (nonatomic) NSInteger offlineUsageLimit;

@property (nonatomic, strong) NSArray *hiddenFeedNames;
@property (nonatomic) BOOL bookmarksNeedUpdate;
@property (nonatomic) BOOL compressPosts;
@property (nonatomic) BOOL dimReadPosts;
@property (nonatomic) BOOL doubleTapToEdit;
@property (nonatomic) BOOL enableAutoCapitalize;
@property (nonatomic) BOOL enableAutoCorrect;
@property (nonatomic) BOOL enableTagAutoCorrect;
@property (nonatomic) BOOL markReadPosts;
@property (nonatomic) BOOL openLinksWithMobilizer;
@property (nonatomic) BOOL openLinksInApp;
@property (nonatomic) BOOL useSafariViewController;
@property (nonatomic) BOOL privateByDefault;
@property (nonatomic) BOOL readByDefault;
@property (nonatomic) BOOL onlyPromptToAddOnce;
@property (nonatomic) BOOL turnOffBookmarkPrompt;
@property (nonatomic) BOOL alwaysShowClipboardNotification;
@property (nonatomic) BOOL hidePrivateLock;
@property (nonatomic) BOOL offlineReadingEnabled;
@property (nonatomic) BOOL useCellularDataForOfflineCache;
@property (nonatomic) BOOL downloadFullWebpageForOfflineCache;
@property (nonatomic) BOOL turnOffPushpinCloudPrompt;

@property (nonatomic, strong) NSString *defaultFeed;
@property (nonatomic, strong) NSArray *personalFeedOrder;
@property (nonatomic, strong) NSString *feedToken;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *fontName;

@property (nonatomic) BOOL purchasedPremiumFonts;


@property (nonatomic, strong) NSArray *communityFeedOrder;

+ (instancetype)sharedSettings;

- (NSString *)username;
- (void)setUsername:(NSString *)username password:(NSString *)password;
- (BOOL)isAuthenticated;

- (NSString *)defaultFeedDescription;
- (UITextAutocapitalizationType)autoCapitalizationType;
- (UITextAutocorrectionType)autoCorrectionType;
- (UITextAutocorrectionType)tagAutoCorrectionType;

@end

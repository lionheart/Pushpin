//
//  PPSettings.m
//  Pushpin
//
//  Created by Dan Loewenherz on 8/10/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

@import KeychainItemWrapper;

#import "PPSettings.h"

@interface PPSettings ()

@end

@implementation PPSettings

@synthesize readLater = _readLater;
@synthesize browser = _browser;
@synthesize mobilizer = _mobilizer;
@synthesize onlyPromptToAddOnce = _onlyPromptToAddOnce;
@synthesize privateByDefault = _privateByDefault;
@synthesize dimReadPosts = _dimReadPosts;
@synthesize enableAutoCorrect = _enableAutoCorrect;
@synthesize enableTagAutoCorrect = _enableTagAutoCorrect;
@synthesize enableAutoCapitalize = _enableAutoCapitalize;
@synthesize readByDefault = _readByDefault;
@synthesize openLinksWithMobilizer = _openLinksWithMobilizer;
@synthesize markReadPosts = _markReadPosts;
@synthesize openLinksInApp = _openLinksInApp;
@synthesize compressPosts = _compressPosts;
@synthesize doubleTapToEdit = _doubleTapToEdit;
@synthesize alwaysShowClipboardNotification = _alwaysShowClipboardNotification;
@synthesize hiddenFeedNames = _hiddenFeedNames;
@synthesize personalFeedOrder = _personalFeedOrder;
@synthesize defaultFeed = _defaultFeed;
@synthesize feedToken = _feedToken;
@synthesize token = _token;
@synthesize lastUpdated = _lastUpdated;
@synthesize username = _username;
@synthesize fontAdjustment = _fontAdjustment;
@synthesize readerSettings = _readerSettings;
@synthesize purchasedPremiumFonts = _purchasedPremiumFonts;
@synthesize fontName = _fontName;
@synthesize hidePrivateLock = _hidePrivateLock;
@synthesize offlineReadingEnabled = _offlineReadingEnabled;
@synthesize useCellularDataForOfflineCache = _useCellularDataForOfflineCache;
@synthesize offlineFetchCriteria = _offlineFetchCriteria;
@synthesize offlineUsageLimit = _offlineUsageLimit;
@synthesize downloadFullWebpageForOfflineCache = _downloadFullWebpageForOfflineCache;
@synthesize turnOffBookmarkPrompt = _turnOffBookmarkPrompt;
@synthesize turnOffPushpinCloudPrompt = _turnOffPushpinCloudPrompt;
@synthesize communityFeedOrder = _communityFeedOrder;

+ (instancetype)sharedSettings {
    static PPSettings *settings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        settings = [[PPSettings alloc] init];
    });
    return settings;
}

- (PPReaderSettings *)readerSettings {
    if (!_readerSettings) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *data = [defaults objectForKey:@"io.aurora.pinboard.ReaderSettings"];
        _readerSettings = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (!_readerSettings) {
            _readerSettings = [[PPReaderSettings alloc] init];
        }
    }
    return _readerSettings;
}

- (void)setReaderSettings:(PPReaderSettings *)readerSettings {
    _readerSettings = readerSettings;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:readerSettings];
    [defaults setObject:data forKey:@"io.aurora.pinboard.ReaderSettings"];
    [defaults synchronize];
}

- (PPFontAdjustmentType)fontAdjustment {
    if (!_fontAdjustment) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _fontAdjustment = [[defaults objectForKey:@"io.aurora.pinboard.FontAdjustment"] integerValue];
    }
    return _fontAdjustment;
}

- (void)setFontAdjustment:(PPFontAdjustmentType)fontAdjustment {
    _fontAdjustment = fontAdjustment;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(fontAdjustment) forKey:@"io.aurora.pinboard.FontAdjustment"];
    [defaults synchronize];
}

- (BOOL)compressPosts {
    if (!_compressPosts) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _compressPosts = [[defaults objectForKey:@"io.aurora.pinboard.CompressPosts"] boolValue];
    }
    return _compressPosts;
}

- (void)setCompressPosts:(BOOL)compressPosts {
    _compressPosts = compressPosts;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(compressPosts) forKey:@"io.aurora.pinboard.CompressPosts"];
    [defaults synchronize];
}

- (BOOL)openLinksWithMobilizer {
    if (!_openLinksWithMobilizer) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _openLinksWithMobilizer = [[defaults objectForKey:@"io.aurora.pinboard.OpenLinksWithMobilizer"] boolValue];
    }
    return _openLinksWithMobilizer;
}

- (void)setOpenLinksWithMobilizer:(BOOL)openLinksWithMobilizer {
    _openLinksWithMobilizer = openLinksWithMobilizer;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(openLinksWithMobilizer) forKey:@"io.aurora.pinboard.OpenLinksWithMobilizer"];
    [defaults synchronize];
}

- (BOOL)dimReadPosts {
    if (!_dimReadPosts) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _dimReadPosts = [[defaults objectForKey:@"io.aurora.pinboard.DimReadPosts"] boolValue];
    }
    return _dimReadPosts;
}

- (void)setDimReadPosts:(BOOL)dimReadPosts {
    _dimReadPosts = dimReadPosts;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(dimReadPosts) forKey:@"io.aurora.pinboard.DimReadPosts"];
    [defaults synchronize];
}

- (BOOL)markReadPosts {
    if (!_markReadPosts) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _markReadPosts = [[defaults objectForKey:@"io.aurora.pinboard.MarkReadPosts"] boolValue];
    }
    return _markReadPosts;
}

- (void)setMarkReadPosts:(BOOL)markReadPosts {
    _markReadPosts = markReadPosts;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(markReadPosts) forKey:@"io.aurora.pinboard.MarkReadPosts"];
    [defaults synchronize];
}

- (BOOL)turnOffBookmarkPrompt {
    if (!_turnOffBookmarkPrompt) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _turnOffBookmarkPrompt = [[defaults objectForKey:@"io.aurora.pinboard.TurnOffBookmarkPrompt"] boolValue];
    }
    return _turnOffBookmarkPrompt;
}

- (void)setTurnOffBookmarkPrompt:(BOOL)turnOffBookmarkPrompt {
    _turnOffBookmarkPrompt = turnOffBookmarkPrompt;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(turnOffBookmarkPrompt) forKey:@"io.aurora.pinboard.TurnOffBookmarkPrompt"];
    [defaults synchronize];
}

- (BOOL)turnOffPushpinCloudPrompt {
    if (!_turnOffPushpinCloudPrompt) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _turnOffPushpinCloudPrompt = [[defaults objectForKey:@"io.aurora.pinboard.TurnOffPushpinCloudPrompt"] boolValue];
    }
    return _turnOffPushpinCloudPrompt;
}

- (void)setTurnOffPushpinCloudPrompt:(BOOL)turnOffPushpinCloudPrompt {
    _turnOffPushpinCloudPrompt = turnOffPushpinCloudPrompt;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(turnOffPushpinCloudPrompt) forKey:@"io.aurora.pinboard.TurnOffBookmarkPrompt"];
    [defaults synchronize];
}

- (BOOL)onlyPromptToAddOnce {
    if (!_onlyPromptToAddOnce) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _onlyPromptToAddOnce = [[defaults objectForKey:@"io.aurora.pinboard.TurnOffPushpinCloudPrompt"] boolValue];
    }
    return _onlyPromptToAddOnce;
}

- (void)setOnlyPromptToAddOnce:(BOOL)onlyPromptToAddOnce {
    _onlyPromptToAddOnce = onlyPromptToAddOnce;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(onlyPromptToAddOnce) forKey:@"io.aurora.pinboard.OnlyPromptToAddOnce"];
    [defaults synchronize];
}

- (BOOL)alwaysShowClipboardNotification {
    if (!_alwaysShowClipboardNotification) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _alwaysShowClipboardNotification = [[defaults objectForKey:@"io.aurora.pinboard.AlwaysShowClipboardNotification"] boolValue];
    }
    return _alwaysShowClipboardNotification;
}

- (void)setAlwaysShowClipboardNotification:(BOOL)alwaysShowClipboardNotification {
    _alwaysShowClipboardNotification = alwaysShowClipboardNotification;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(alwaysShowClipboardNotification) forKey:@"io.aurora.pinboard.AlwaysShowClipboardNotification"];
    [defaults synchronize];
}

- (BOOL)enableAutoCorrect {
    if (!_enableAutoCorrect) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _enableAutoCorrect = [[defaults objectForKey:@"io.aurora.pinboard.EnableAutoCorrect"] boolValue];
        
        if (!_enableAutoCorrect) {
            NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
            _enableAutoCorrect = [[sharedDefaults objectForKey:@"EnableAutoCorrect"] boolValue];
        }
    }
    return _enableAutoCorrect;
}

- (void)setEnableAutoCorrect:(BOOL)enableAutoCorrect {
    _enableAutoCorrect = enableAutoCorrect;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(enableAutoCorrect) forKey:@"io.aurora.pinboard.EnableAutoCorrect"];
    [defaults synchronize];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [sharedDefaults setObject:@(enableAutoCorrect) forKey:@"EnableAutoCorrect"];
}

- (BOOL)enableTagAutoCorrect {
    if (!_enableTagAutoCorrect) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _enableTagAutoCorrect = [[defaults objectForKey:@"io.aurora.pinboard.EnableTagAutoCorrect"] boolValue];
        
        if (!_enableTagAutoCorrect) {
            NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
            _enableTagAutoCorrect = [[sharedDefaults objectForKey:@"EnableTagAutoCorrect"] boolValue];
        }
    }
    return _enableTagAutoCorrect;
}

- (void)setEnableTagAutoCorrect:(BOOL)enableTagAutoCorrect {
    _enableTagAutoCorrect = enableTagAutoCorrect;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(enableTagAutoCorrect) forKey:@"io.aurora.pinboard.EnableTagAutoCorrect"];
    [defaults synchronize];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [sharedDefaults setObject:@(enableTagAutoCorrect) forKey:@"EnableTagAutoCorrect"];
}

- (BOOL)enableAutoCapitalize {
    if (!_enableAutoCapitalize) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _enableAutoCapitalize = [[defaults objectForKey:@"io.aurora.pinboard.EnableAutoCapitalize"] boolValue];
        
        if (!_enableAutoCapitalize) {
            NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
            _enableAutoCapitalize = [[sharedDefaults objectForKey:@"EnableAutoCapitalize"] boolValue];
        }
    }
    return _enableAutoCapitalize;
}

- (void)setEnableAutoCapitalize:(BOOL)enableAutoCapitalize {
    _enableAutoCapitalize = enableAutoCapitalize;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(enableAutoCapitalize) forKey:@"io.aurora.pinboard.EnableAutoCapitalize"];
    [defaults synchronize];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [sharedDefaults setObject:@(enableAutoCapitalize) forKey:@"EnableAutoCapitalize"];
}

- (void)setBrowser:(PPBrowserType)browser {
    _browser = browser;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(browser) forKey:@"io.aurora.pinboard.Browser"];
    [defaults synchronize];
}

- (PPBrowserType)browser {
    if (!_browser) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *result = [defaults objectForKey:@"io.aurora.pinboard.Browser"];
        
        if (result) {
            _browser = [result integerValue];
            
            if (_browser == PPBrowserWebview) {
                _browser = PPBrowserSafari;
            }
        }
        else {
            _browser = PPBrowserSafari;
        }
    }
    return _browser;
}

- (void)setFeedToken:(NSString *)feedToken {
    _feedToken = feedToken;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:feedToken forKey:@"io.aurora.pinboard.FeedToken"];
    [defaults synchronize];
}

- (NSString *)feedToken {
    if (!_feedToken) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _feedToken = [defaults objectForKey:@"io.aurora.pinboard.FeedToken"];
    }
    return _feedToken;
}

- (void)setReadLater:(PPReadLaterType)readLater{
    _readLater = readLater;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(readLater) forKey:@"io.aurora.pinboard.ReadLater"];
    [defaults synchronize];
}

- (PPReadLaterType)readLater {
    if (!_readLater) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *result = [defaults objectForKey:@"io.aurora.pinboard.ReadLater"];
        
        if (result) {
            _readLater = [result integerValue];
        }
        else {
            _readLater = PPReadLaterNone;
        }
    }
    return _readLater;
}

- (void)setMobilizer:(PPMobilizerType)mobilizer {
    _mobilizer = mobilizer;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(mobilizer) forKey:@"io.aurora.pinboard.Mobilizer"];
    [defaults synchronize];
}

- (PPMobilizerType)mobilizer {
    if (!_mobilizer) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *result = [defaults objectForKey:@"io.aurora.pinboard.Mobilizer"];
        
        if (result) {
            _mobilizer = [result integerValue];
        }
        else {
            _mobilizer = PPMobilizerInstapaper;
        }
    }
    return _mobilizer;
}

- (NSArray *)hiddenFeedNames {
    if (!_hiddenFeedNames) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _hiddenFeedNames = [defaults objectForKey:@"io.aurora.pinboard.HiddenFeedNames"];
    }
    return _hiddenFeedNames;
}

- (void)setHiddenFeedNames:(NSArray *)hiddenFeedNames {
    _hiddenFeedNames = hiddenFeedNames;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:hiddenFeedNames forKey:@"io.aurora.pinboard.HiddenFeedNames"];
    [defaults synchronize];
}

- (NSArray *)personalFeedOrder {
    if (!_personalFeedOrder) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _personalFeedOrder = [defaults objectForKey:@"io.aurora.pinboard.PersonalFeedOrder"];
    }
    return _personalFeedOrder;
}

- (void)setPersonalFeedOrder:(NSArray *)personalFeedOrder {
    _personalFeedOrder = personalFeedOrder;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:personalFeedOrder forKey:@"io.aurora.pinboard.PersonalFeedOrder"];
    [defaults synchronize];
}



- (NSArray *)communityFeedOrder {
    if (!_communityFeedOrder) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _communityFeedOrder = [defaults objectForKey:@"io.aurora.pinboard.CommunityFeedOrder"];
    }
    return _communityFeedOrder;
}

- (void)setCommunityFeedOrder:(NSArray *)communityFeedOrder {
    _communityFeedOrder = communityFeedOrder;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:communityFeedOrder forKey:@"io.aurora.pinboard.CommunityFeedOrder"];
    [defaults synchronize];
}


- (void)setPrivateByDefault:(BOOL)privateByDefault {
    _privateByDefault = privateByDefault;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(privateByDefault) forKey:@"io.aurora.pinboard.PrivateByDefault"];
    [defaults synchronize];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [sharedDefaults setObject:@(privateByDefault) forKey:@"PrivateByDefault"];
}

- (BOOL)privateByDefault {
    if (!_privateByDefault) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _privateByDefault = [[defaults objectForKey:@"io.aurora.pinboard.PrivateByDefault"] boolValue];
    }
    return _privateByDefault;
}

- (BOOL)openLinksInApp {
    if (!_openLinksInApp) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _openLinksInApp = [[defaults objectForKey:@"io.aurora.pinboard.OpenLinksInApp"] boolValue];
    }
    return _openLinksInApp;
}

- (void)setOpenLinksInApp:(BOOL)openLinksInApp {
    _openLinksInApp = openLinksInApp;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(openLinksInApp) forKey:@"io.aurora.pinboard.OpenLinksInApp"];
    [defaults synchronize];
}

- (void)setDoubleTapToEdit:(BOOL)doubleTapToEdit {
    _doubleTapToEdit = doubleTapToEdit;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(doubleTapToEdit) forKey:@"io.aurora.pinboard.DoubleTapToEdit"];
    [defaults synchronize];
}

- (BOOL)doubleTapToEdit {
    if (!_doubleTapToEdit) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _doubleTapToEdit = [[defaults objectForKey:@"io.aurora.pinboard.DoubleTapToEdit"] boolValue];
    }
    return _doubleTapToEdit;
}

- (void)setReadByDefault:(BOOL)readByDefault {
    _readByDefault = readByDefault;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(readByDefault) forKey:@"io.aurora.pinboard.ReadByDefault"];
    [defaults synchronize];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [sharedDefaults setObject:@(readByDefault) forKey:@"ReadByDefault"];
}

- (BOOL)readByDefault {
    if (!_readByDefault) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _readByDefault = [[defaults objectForKey:@"io.aurora.pinboard.ReadByDefault"] boolValue];
    }
    return _readByDefault;
}

- (void)setDefaultFeed:(NSString *)defaultFeed {
    _defaultFeed = defaultFeed;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_defaultFeed forKey:@"io.aurora.pinboard.DefaultFeed"];
}

- (NSString *)defaultFeed {
    if (!_defaultFeed) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _defaultFeed = [defaults objectForKey:@"io.aurora.pinboard.DefaultFeed"];
        if (!_defaultFeed) {
            _defaultFeed = @"personal-all";
        }
    }
    
    return _defaultFeed;
}

- (void)setToken:(NSString *)token {
    _token = token;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:@"io.aurora.pinboard.Token"];
    [defaults synchronize];

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP];
    [sharedDefaults setObject:token forKey:@"token"];
}

- (NSString *)token {
#ifdef TOKEN
    return TOKEN;
#else
    if (!_token) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _token = [defaults objectForKey:@"io.aurora.pinboard.Token"];
    }
    return _token;
#endif
}

- (void)setLastUpdated:(NSDate *)lastUpdated {
    _lastUpdated = lastUpdated;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lastUpdated forKey:@"io.aurora.pinboard.LastUpdated"];
    [defaults synchronize];
}

- (NSDate *)lastUpdated {
    if (!_lastUpdated) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _lastUpdated = [defaults objectForKey:@"io.aurora.pinboard.LastUpdated"];
    }
    return _lastUpdated;
}

- (void)setFontName:(NSString *)fontName {
    _fontName = fontName;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:fontName forKey:@"io.aurora.pinboard.BrowseFontName"];
    [defaults synchronize];
}

- (NSString *)fontName {
    if (!_fontName) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _fontName = [defaults objectForKey:@"io.aurora.pinboard.BrowseFontName"];
    }
    return _fontName;
}

- (NSString *)username {
    

    return [self.token componentsSeparatedByString:@":"][0];
}

- (void)setUsername:(NSString *)username {
    [self setUsername:username password:nil];
}

- (NSString *)password {
    

    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"PinboardCredentials" accessGroup:nil];
    
    NSString *key = [keychain objectForKey:(__bridge id)kSecValueData];
    if ([key isEqualToString:@""]) {
        return nil;
    }
    return key;
}

- (void)setPassword:(NSString *)password {
    [self setUsername:nil password:password];
}

- (void)setUsername:(NSString *)username password:(NSString *)password {
    

    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"PinboardCredentials" accessGroup:nil];
    
    if (username) {
        [keychain setObject:username forKey:(__bridge id)kSecAttrAccount];
    }
    
    if (password) {
        [keychain setObject:password forKey:(__bridge id)kSecValueData];
    }
}

- (BOOL)isAuthenticated {
    

    return self.token != nil;
}

- (NSString *)defaultFeedDescription {
    // Build a descriptive string for the default feed
    NSString *feedDescription = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Personal", nil), @"All"];
    if (self.defaultFeed) {
        if ([self.defaultFeed hasPrefix:@"personal-"]) {
            feedDescription = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Personal", nil), [[self.defaultFeed substringFromIndex:9] capitalizedString]];
        }
        else if ([self.defaultFeed hasPrefix:@"community-"]) {
            NSString *communityDescription = [self.defaultFeed substringFromIndex:10];
            if ([communityDescription isEqualToString:@"japanese"]) {
                communityDescription = @"日本語";
            }
            feedDescription = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Community", nil), [communityDescription capitalizedString]];
        }
        else if ([self.defaultFeed hasPrefix:@"saved-"]) {
            feedDescription = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Saved Feed", nil), [self.defaultFeed substringFromIndex:6]];
        }
        else if ([self.defaultFeed hasPrefix:@"search-"]) {
            feedDescription = [NSString stringWithFormat:@"%@ : %@", NSLocalizedString(@"Search", nil), [self.defaultFeed substringFromIndex:7]];
        }
    }
    return feedDescription;
}

- (UITextAutocapitalizationType)autoCapitalizationType {
    return self.enableAutoCapitalize ? UITextAutocapitalizationTypeSentences : UITextAutocapitalizationTypeNone;
}

- (UITextAutocorrectionType)autoCorrectionType {
    return self.enableAutoCorrect ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo;
}

- (UITextAutocorrectionType)tagAutoCorrectionType {
    return self.enableTagAutoCorrect ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo;
}

- (BOOL)purchasedPremiumFonts {
    if (!_purchasedPremiumFonts) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _purchasedPremiumFonts = [defaults boolForKey:@"io.aurora.pinboard.PurchasedPremiumFonts"];
    }
    return _purchasedPremiumFonts;
}

- (void)setPurchasedPremiumFonts:(BOOL)purchasedPremiumFonts {
    _purchasedPremiumFonts = purchasedPremiumFonts;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:purchasedPremiumFonts forKey:@"io.aurora.pinboard.PurchasedPremiumFonts"];
    [defaults synchronize];
}

- (BOOL)hidePrivateLock {
    if (!_hidePrivateLock) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _hidePrivateLock = [defaults boolForKey:@"io.aurora.pinboard.HidePrivateLock"];
    }
    return _hidePrivateLock;
}

- (void)setHidePrivateLock:(BOOL)hidePrivateLock {
    _hidePrivateLock = hidePrivateLock;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:hidePrivateLock forKey:@"io.aurora.pinboard.HidePrivateLock"];
    [defaults synchronize];
}

- (BOOL)offlineReadingEnabled {
    if (!_offlineReadingEnabled) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _offlineReadingEnabled = [defaults boolForKey:@"io.aurora.pinboard.OfflineReadingEnabled"];
    }
    return _offlineReadingEnabled;
}

- (void)setOfflineReadingEnabled:(BOOL)offlineReadingEnabled {
    _offlineReadingEnabled = offlineReadingEnabled;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:offlineReadingEnabled forKey:@"io.aurora.pinboard.OfflineReadingEnabled"];
    [defaults synchronize];
}

- (BOOL)useCellularDataForOfflineCache {
    if (!_useCellularDataForOfflineCache) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _useCellularDataForOfflineCache = [defaults boolForKey:@"io.aurora.pinboard.UseCellularDataForOffline"];
    }
    return _useCellularDataForOfflineCache;
}

- (void)setUseCellularDataForOfflineCache:(BOOL)useCellularDataForOfflineCache {
    _useCellularDataForOfflineCache = useCellularDataForOfflineCache;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:useCellularDataForOfflineCache forKey:@"io.aurora.pinboard.UseCellularDataForOffline"];
    [defaults synchronize];
}

- (BOOL)downloadFullWebpageForOfflineCache {
    if (!_downloadFullWebpageForOfflineCache) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _downloadFullWebpageForOfflineCache = [defaults boolForKey:@"io.aurora.pinboard.DownloadFullWebpageForOffline"];
    }
    return _downloadFullWebpageForOfflineCache;
}

- (void)setDownloadFullWebpageForOfflineCache:(BOOL)downloadFullWebpageForOfflineCache {
    _downloadFullWebpageForOfflineCache = downloadFullWebpageForOfflineCache;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:downloadFullWebpageForOfflineCache forKey:@"io.aurora.pinboard.DownloadFullWebpageForOffline"];
    [defaults synchronize];
}

- (void)setOfflineFetchCriteria:(PPOfflineFetchCriteriaType)offlineFetchCriteria {
    _offlineFetchCriteria = offlineFetchCriteria;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(offlineFetchCriteria) forKey:@"io.aurora.pinboard.OfflineFetchCriteria"];
    [defaults synchronize];
}

- (PPOfflineFetchCriteriaType)offlineFetchCriteria {
    if (!_offlineFetchCriteria) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _offlineFetchCriteria = [[defaults objectForKey:@"io.aurora.pinboard.OfflineFetchCriteria"] integerValue];
    }
    return _offlineFetchCriteria;
}

- (void)setOfflineUsageLimit:(NSInteger)offlineUsageLimit {
    _offlineUsageLimit = offlineUsageLimit;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:offlineUsageLimit forKey:@"io.aurora.pinboard.OfflineUsageLimit"];
    [defaults synchronize];
}

- (NSInteger)offlineUsageLimit {
    if (!_offlineUsageLimit) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _offlineUsageLimit = [defaults integerForKey:@"io.aurora.pinboard.OfflineUsageLimit"];
    }
    return _offlineUsageLimit;
}

@end

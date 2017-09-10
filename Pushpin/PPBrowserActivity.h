//
//  PPBrowserActivity.h
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

@import UIKit;

// https://github.com/mozilla-mobile/firefox-ios-open-in-client/blob/master/OpenInFirefoxClient/OpenInFirefoxControllerObjC.m
static NSString *encodeByAddingPercentEscapes(NSString *string) {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                    kCFAllocatorDefault,
                                                                                                    (CFStringRef)string,
                                                                                                    NULL,
                                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8));
    return encodedString;
}

@interface PPBrowserActivity : UIActivity

@property (nonatomic, retain) NSString *urlScheme;
@property (nonatomic, retain) NSString *browserName;
@property (nonatomic, retain) NSString *urlString;

- (id)initWithUrlScheme:(NSString *)scheme;
- (id)initWithUrlScheme:(NSString *)scheme browser:(NSString *)browser;

@end

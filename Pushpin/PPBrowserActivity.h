/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Pushpin for Pinboard
 * Copyright (C) 2025 Lionheart Software LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pushpin for Pinboard
// Copyright (C) 2025 Lionheart Software LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

//
//  PPMobilizerUtility.m
//  Pushpin
//
//  Created by Dan Loewenherz on 1/5/14.
//
//

#import "PPMobilizerUtility.h"
#import "PPSettings.h"
#import "NSString+URLEncoding2.h"

@interface PPMobilizerUtility ()

- (PPMobilizerType)mobilizer;

@end

@implementation PPMobilizerUtility

+ (instancetype)sharedInstance {
    static PPMobilizerUtility *mobilizer;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mobilizer = [[PPMobilizerUtility alloc] init];
    });

    return mobilizer;
}

- (PPMobilizerType)mobilizer {
    return [[PPSettings sharedSettings] mobilizer];
}

+ (BOOL)canMobilizeURL:(NSURL *)url {
    return ![@[@"twitter.com", @"mobile.twitter.com", @"marco.org"] containsObject:url.host];
}

- (BOOL)isURLMobilized:(NSURL *)url {
    return [self isURLMobilized:url mobilizer:self.mobilizer];
}

- (NSString *)urlStringForMobilizerForURL:(NSURL *)url {
    return [self urlStringForMobilizerForURL:url forMobilizer:self.mobilizer];
}

- (NSString *)originalURLStringForURL:(NSURL *)url {
    return [self originalURLStringForURL:url forMobilizer:self.mobilizer];
}

- (BOOL)isURLMobilized:(NSURL *)url mobilizer:(PPMobilizerType)mobilizer {
    BOOL googleMobilized = [url.absoluteString hasPrefix:@"http://www.google.com/gwt/x"];
    BOOL readabilityMobilized = [url.absoluteString hasPrefix:@"http://www.readability.com/m?url="];
    BOOL instapaperMobilized = [url.absoluteString hasPrefix:@"http://mobilizer.instapaper.com/m?u="];
    return googleMobilized || readabilityMobilized || instapaperMobilized;
}

- (NSString *)urlStringForMobilizerForURL:(NSURL *)url forMobilizer:(PPMobilizerType)mobilizer {
    switch (mobilizer) {
        case PPMobilizerGoogle:
            return [NSString stringWithFormat:@"http://www.google.com/gwt/x?noimg=1&bie=UTF-8&oe=UTF-8&u=%@", url.absoluteString];

        case PPMobilizerInstapaper:
            return [NSString stringWithFormat:@"http://mobilizer.instapaper.com/m?u=%@", url.absoluteString];

        case PPMobilizerReadability:
            return [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", url.absoluteString];
    }
}

- (NSString *)originalURLStringForURL:(NSURL *)url forMobilizer:(PPMobilizerType)mobilizer {
    if ([self isURLMobilized:url mobilizer:mobilizer]) {
        switch (mobilizer) {
            case PPMobilizerGoogle:
                return [url.absoluteString substringFromIndex:57];

            case PPMobilizerInstapaper:
                return [url.absoluteString substringFromIndex:36];

            case PPMobilizerReadability:
                return [url.absoluteString substringFromIndex:33];
        }
    }
    return url.absoluteString;
}

@end


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
//  PinboardFeedDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/22/13.
//
//

@import Foundation;

#import "PPGenericPostViewController.h"

@class PostMetadata;

static dispatch_queue_t PPPinboardFeedReloadQueue () {
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("io.aurora.Pushpin.PinboardFeedReloadQueue", 0);
    });
    return queue;
}

@interface PPPinboardFeedDataSource : NSObject <PPDataSource>

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSArray *components;
@property (nonatomic, strong) NSArray *metadata;
@property (nonatomic, strong) NSArray *compressedMetadata;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSMutableArray *expandedIndices;
@property (nonatomic) NSInteger count;

- (NSURL *)url;
- (id)initWithComponents:(NSArray *)components;
+ (PPPinboardFeedDataSource *)dataSourceWithComponents:(NSArray *)components;
+ (PPGenericPostViewController *)postViewControllerWithComponents:(NSArray *)components;

- (NSAttributedString *)trimTrailingPunctuationFromAttributedString:(NSAttributedString *)string trimmedLength:(NSUInteger *)trimmed;

- (NSAttributedString *)stringByTrimmingTrailingPunctuationFromAttributedString:(NSAttributedString *)string offset:(NSInteger *)offset;

@end

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
//  PostMetadata.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

@import Foundation;

@class PPBadgeWrapperView;

@interface PostMetadata : NSObject

@property (nonatomic, strong) NSAttributedString *titleString;
@property (nonatomic, strong) NSAttributedString *descriptionString;
@property (nonatomic, strong) NSAttributedString *linkString;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSArray *badges;
@property (nonatomic) CGFloat titleHeight;
@property (nonatomic) CGFloat badgeHeight;
@property (nonatomic) CGFloat descriptionHeight;
@property (nonatomic) CGFloat linkHeight;

@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;

+ (PostMetadata *)metadataForPost:(NSDictionary *)post
                       compressed:(BOOL)compressed
                            width:(CGFloat)width
                tagsWithFrequency:(NSDictionary *)tagsWithFrequency
                            cache:(BOOL)cache;

+ (PostMetadata *)metadataForPost:(NSDictionary *)post
                       compressed:(BOOL)compressed
                            width:(CGFloat)width
                tagsWithFrequency:(NSDictionary *)tagsWithFrequency;

@end

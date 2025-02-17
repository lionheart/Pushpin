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
//  NSString+LHSAdditions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/13/14.
//
//

#import "NSString+LHSAdditions.h"

@implementation NSString (LHSAdditions2)

- (NSInteger)lhs_IntegerIfNotNull {
#warning XXX Does not work, since NSNull must have a category with the same name.
    if ([self isEqual:[NSNull null]]) {
        return 0;
    } else {
        return [self integerValue];
    }
}

- (NSString *)lhs_stringByTrimmingWhitespace {
#warning XXX Does not work, since NSNull must have a category with the same name.
    if ([self isEqual:[NSNull null]]) {
        return @"";
    } else {
        return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

@end


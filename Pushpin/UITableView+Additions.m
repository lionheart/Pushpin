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
//  UITableView+Additions.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/25/13.
//
//

#import "UITableView+Additions.h"

@implementation UITableView (Additions)

- (CGFloat)groupedCellMargin {
    CGFloat marginWidth;
    CGFloat tableViewWidth = CGRectGetWidth(self.frame);
    if (tableViewWidth > 20) {
        if (tableViewWidth < 400) {
            marginWidth = 10;
        } else {
            marginWidth = MAX(31, MIN(45, tableViewWidth*0.06));
        }
    } else {
        marginWidth = tableViewWidth - 10;
    }
    return marginWidth;
}

@end

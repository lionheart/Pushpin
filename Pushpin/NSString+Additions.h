//
//  NSString+Additions.h
//  Pushpin
//
//  Created by Dan Loewenherz on 1/4/15.
//  Copyright (c) 2015 Lionheart Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (BOOL)isReadabilityURL;
- (NSString *)originalURLString;

@end

//
//  Bookmark.h
//  ASPinboard
//
//  Created by Daniel Loewenherz on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Bookmark : NSObject

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *time;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *extended;
@property (nonatomic, retain) NSString *tag;
@property (nonatomic, retain) NSString *hash;
@property (nonatomic, retain) NSNumber *read;

+ (Bookmark *)bookmarkWithURL:(NSString *)url 
                         time:(NSString *)time
                  description:(NSString *)description
                     extended:(NSString *)extended
                          tag:(NSString *)tag
                         hash:(NSString *)hash
                         read:(NSNumber *)read;

+ (Bookmark *)bookmarkWithAttributes:(NSDictionary *)attributes;

@end

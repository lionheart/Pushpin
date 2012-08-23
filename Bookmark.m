//
//  Bookmark.m
//  ASPinboard
//
//  Created by Daniel Loewenherz on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Bookmark.h"

@implementation Bookmark

@synthesize url;
@synthesize time;
@synthesize description;
@synthesize extended;
@synthesize tag;
@synthesize hash;
@synthesize read;

+ (Bookmark *)bookmarkWithURL:(NSString *)url time:(NSString *)time description:(NSString *)description extended:(NSString *)extended tag:(NSString *)tag hash:(NSString *)hash read:(NSNumber *)read {
    Bookmark *bookmark = [[Bookmark alloc] init];
    bookmark.url = url;
    bookmark.time = time;
    bookmark.description = description;
    bookmark.extended = extended;
    bookmark.tag = tag;
    bookmark.hash = hash;
    bookmark.read = read;
    return bookmark;
}

+ (Bookmark *)bookmarkWithAttributes:(NSDictionary *)attributes {
    NSString *url = [attributes objectForKey:@"href"];
    NSString *time = [attributes objectForKey:@"time"];
    NSString *description = [attributes objectForKey:@"description"];
    NSString *extended = [attributes objectForKey:@"extended"];
    NSString *tag = [attributes objectForKey:@"tag"];
    NSString *hash = [attributes objectForKey:@"hash"];
    NSNumber *read = [NSNumber numberWithBool:([attributes objectForKey:@"toread"] == nil)];
    
    return [Bookmark bookmarkWithURL:url
                                time:time
                         description:description
                            extended:extended
                                 tag:tag
                                hash:hash
                                read:read];
}

@end

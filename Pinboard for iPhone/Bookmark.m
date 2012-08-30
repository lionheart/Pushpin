//
//  Bookmark.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 8/28/12.
//
//

#import "Bookmark.h"
#import "ASManagedObject.h"

@implementation Bookmark

@dynamic created_on;
@dynamic extended;
@dynamic meta;
@dynamic others;
@dynamic read;
@dynamic title;
@dynamic url;
@dynamic pinboard_hash;
@dynamic tags;

+ (Bookmark *)bookmarkWithAttributes:(NSDictionary *)attributes {
    NSString *url = [attributes objectForKey:@"href"];
    NSString *time = [attributes objectForKey:@"time"];
    NSString *title = [attributes objectForKey:@"description"];
    NSString *extended = [attributes objectForKey:@"extended"];
    NSString *tag = [attributes objectForKey:@"tag"];
    NSString *hash = [attributes objectForKey:@"hash"];
    NSNumber *read = [NSNumber numberWithBool:([attributes objectForKey:@"toread"] == nil)];

    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    bookmark.url = url;
    bookmark.title = title;
    bookmark.pinboard_hash = hash;
    bookmark.extended = extended;
    bookmark.read = read;
    return bookmark;
}

@end

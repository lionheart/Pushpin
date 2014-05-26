//
//  PPUtilities.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/14/14.
//
//

#import "PPUtilities.h"
#import <FMDB/FMDatabase.h>

@implementation PPUtilities

+ (NSString *)stringByTrimmingWhitespace:(id)object {
    if ([object isEqual:[NSNull null]]) {
        return @"";
    }
    else {
        return [(NSString *)object stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

+ (void)generateDiffForPrevious:(NSArray *)previousItems
                        updated:(NSArray *)updatedItems
                           hash:(NSString *(^)(id))extractHash
                           meta:(NSString *(^)(id))extractMeta
                     completion:(void (^)(NSSet *inserted, NSSet *updated, NSSet *deleted))completion {
    
    // Three things we want to do here:
    //
    // 1. Add new bookmarks.
    // 2. Update existing bookmarks.
    // 3. Delete removed bookmarks.
    //
    // Let's call "before update" A, and "after update" B.
    // For 1, we want all bookmarks in B but not in A. So [B minusSet:A]
    // For 3, we want all bookmarks in A but not in B. So [A minusSet:B]
    // For 2, we do [B minusSet:A], but with hashes + meta instead of just hashes as keys.
    NSMutableSet *A = [NSMutableSet set];
    NSMutableSet *B = [NSMutableSet set];
    NSMutableSet *APlusMeta = [NSMutableSet set];
    NSMutableSet *BPlusMeta = [NSMutableSet set];
    
    NSMutableSet *inserted = [NSMutableSet set];
    NSMutableSet *deleted = [NSMutableSet set];
    NSMutableSet *updated = [NSMutableSet set];
    
    NSMutableSet *insertedBookmarkPlusMetaSet = [NSMutableSet set];
    NSMutableDictionary *identifiersToChanges = [NSMutableDictionary dictionary];
    
    if (extractMeta) {
        for (id obj in previousItems) {
            NSString *hash = extractHash(obj);
            [A addObject:hash];
            
            NSString *meta = extractMeta(obj);
            NSString *hashmeta = [@[hash, meta] componentsJoinedByString:@"_"];
            [APlusMeta addObject:hashmeta];
        }
        
        for (id obj in updatedItems) {
            NSString *hash = extractHash(obj);
            
            [B addObject:hash];
            
            NSString *meta = extractMeta(obj);
            NSString *hashmeta = [@[hash, meta] componentsJoinedByString:@"_"];
            [APlusMeta addObject:hashmeta];
            identifiersToChanges[hash] = meta;
        }
    }
    else {
        for (id obj in previousItems) {
            NSString *hash = extractHash(obj);
            [A addObject:hash];
        }
        
        for (id obj in updatedItems) {
            NSString *hash = extractHash(obj);
            
            [B addObject:hash];
        }
    }
    
    // Now we figure out our syncing.
    [inserted setSet:B];
    [inserted minusSet:A];
    
    // This gives us all bookmarks in 'A' but not in 'B'.
    [deleted setSet:A];
    [deleted minusSet:B];
    
    if (extractMeta) {
        for (NSString *identifier in inserted) {
            [insertedBookmarkPlusMetaSet addObject:[@[identifier, identifiersToChanges[identifier]] componentsJoinedByString:@"_"]];
        }
        
        [updated setSet:BPlusMeta];
        [updated minusSet:APlusMeta];
        [updated minusSet:insertedBookmarkPlusMetaSet];
    }
    
    completion(inserted, updated, deleted);
}

+ (void)generateDiffForPrevious:(NSArray *)previousItems
                        updated:(NSArray *)updatedItems
                           hash:(NSString *(^)(id))extractHash
                     completion:(void (^)(NSSet *, NSSet *))completion {
    [self generateDiffForPrevious:previousItems
                          updated:updatedItems
                             hash:extractHash
                             meta:nil
                       completion:^(NSSet *inserted, NSSet *updated, NSSet *deleted) {
                           completion(inserted, deleted);
                       }];
}

+ (NSDictionary *)dictionaryFromResultSet:(id)resultSet {
#ifdef PINBOARD
    NSNumber *starred = @([resultSet boolForColumn:@"starred"]);
    if (!starred) {
        starred = @(NO);
    }
    return @{
             @"title": [resultSet stringForColumn:@"title"],
             @"description": [resultSet stringForColumn:@"description"],
             @"unread": @([resultSet boolForColumn:@"unread"]),
             @"url": [resultSet stringForColumn:@"url"],
             @"private": @([resultSet boolForColumn:@"private"]),
             @"tags": [resultSet stringForColumn:@"tags"],
             @"created_at": [resultSet dateForColumn:@"created_at"],
             @"starred": starred
             };
#endif

#ifdef DELICIOUS
    NSString *title = [resultSet stringForColumn:@"title"];
    
    if ([title isEqualToString:@""]) {
        title = @"untitled";
    }
    
    NSString *hash = [resultSet stringForColumn:@"hash"];
    if (!hash) {
        hash = @"";
    }

    return @{
             @"title": title,
             @"description": [resultSet stringForColumn:@"description"],
             @"unread": @([resultSet boolForColumn:@"unread"]),
             @"url": [resultSet stringForColumn:@"url"],
             @"tags": [resultSet stringForColumn:@"tags"],
             @"created_at": [resultSet dateForColumn:@"created_at"],
             @"hash": hash,
             @"meta": [resultSet stringForColumn:@"meta"],
             };
#endif
}

@end

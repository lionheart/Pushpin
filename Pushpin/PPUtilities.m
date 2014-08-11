//
//  PPUtilities.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/14/14.
//
//

#import "PPUtilities.h"

#import <SafariServices/SafariServices.h>
#import <FMDB/FMDatabase.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <PocketAPI/PocketAPI.h>
#import <oauthconsumer/OAuthConsumer.h>

@implementation PPUtilities

+ (NSString *)stringByTrimmingWhitespace:(id)object {
    if (!object || [object isEqual:[NSNull null]]) {
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
            [BPlusMeta addObject:hashmeta];
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

+ (void)shareToReadLaterWithURL:(NSString *)url title:(NSString *)title {
    [self shareToReadLaterWithURL:url title:title delay:0];
}

+ (void)shareToReadLaterWithURL:(NSString *)url title:(NSString *)title delay:(CGFloat)seconds completion:(void (^)())completion {
    PPSettings *settings = [PPSettings sharedSettings];
    PPReadLaterType readLater = settings.readLater;
    [self shareToReadLater:readLater URL:url title:title delay:seconds completion:completion];
}

+ (void)shareToReadLater:(PPReadLaterType)readLater URL:(NSString *)url title:(NSString *)title delay:(CGFloat)seconds completion:(void (^)())completion {
    if (!completion) {
        completion = ^{};
    }

    PPSettings *settings = [PPSettings sharedSettings];
    switch (readLater) {
        case PPReadLaterInstapaper: {
            if (settings.instapaperToken) {
                NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.instapaper.com/api/1.1/bookmarks/add"]];
                OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint
                                                                               consumer:[PPConstants instapaperConsumer]
                                                                                  token:settings.instapaperToken
                                                                                  realm:nil
                                                                      signatureProvider:nil];
                [request setHTTPMethod:@"POST"];
                NSMutableArray *parameters = [[NSMutableArray alloc] init];
                [parameters addObject:[OARequestParameter requestParameter:@"url" value:url]];
                [request setParameters:parameters];
                [request prepare];
                
                [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
                [NSURLConnection sendAsynchronousRequest:request
                                                   queue:[NSOperationQueue mainQueue]
                                       completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                           [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                                           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                           
                                           BOOL success = NO;
                                           BOOL updated = NO;
                                           NSString *message;
                                           if (httpResponse.statusCode == 200) {
                                               success = YES;
                                               message = NSLocalizedString(@"Sent to Instapaper.", nil);
                                               [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Instapaper"}];
                                           }
                                           else if (httpResponse.statusCode == 1221) {
                                               message = NSLocalizedString(@"Publisher opted out of Instapaper compatibility.", nil);
                                           }
                                           else {
                                               message = NSLocalizedString(@"Error sending to Instapaper.", nil);
                                           }
                                           
                                           completion();
                                           [PPNotification notifyWithMessage:message success:success updated:updated delay:seconds];
                                       }];
            }
            else {
                [PPNotification notifyWithMessage:NSLocalizedString(@"Instapaper credentials have expired. Please re-authenticate and try again.", nil)
                                         userInfo:nil
                                            delay:seconds];
            }
            break;
        }
            
        case PPReadLaterReadability: {
            NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.readability.com/api/rest/v1/bookmarks"]];

            OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:endpoint
                                                                           consumer:[PPConstants readabilityConsumer]
                                                                              token:settings.readabilityToken
                                                                              realm:nil
                                                                  signatureProvider:nil];
            [request setHTTPMethod:@"POST"];
            [request setParameters:@[[OARequestParameter requestParameter:@"url" value:url]]];
            [request prepare];
            
            [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                                       
                                       NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                       BOOL success = NO;
                                       BOOL updated = NO;
                                       NSString *message;
                                       if (httpResponse.statusCode == 202) {
                                           message = NSLocalizedString(@"Sent to Readability.", nil);
                                           success = YES;
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Readability"}];
                                       }
                                       else if (httpResponse.statusCode == 409) {
                                           message = NSLocalizedString(@"Link already sent to Readability.", nil);
                                       }
                                       else {
                                           message = NSLocalizedString(@"Error sending to Readability.", nil);
                                       }
                                       
                                       completion();
                                       [PPNotification notifyWithMessage:message success:success updated:updated delay:seconds];
                                   }];
            break;
        }
            
        case PPReadLaterPocket: {
            [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
            [[PocketAPI sharedAPI] saveURL:[NSURL URLWithString:url]
                                 withTitle:title
                                   handler:^(PocketAPI *api, NSURL *url, NSError *error) {
                                       [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                                       completion();

                                       if (!error) {
                                           [PPNotification notifyWithMessage:NSLocalizedString(@"Sent to Pocket.", nil)
                                                                     success:YES
                                                                     updated:NO
                                                                       delay:seconds];
                                           
                                           [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Pocket"}];
                                       }
                                   }];
        }
            
        case PPReadLaterNative: {
            completion();
            
            // Add to the native Reading List
            NSError *error;
            [[SSReadingList defaultReadingList] addReadingListItemWithURL:[NSURL URLWithString:url]
                                                                    title:title
                                                              previewText:nil
                                                                    error:&error];
            
            NSString *message;
            BOOL success = NO;
            BOOL updated = NO;
            if (error) {
                message = @"Error adding to Reading List";
            }
            else {
                message = @"Added to Reading List";
                success = YES;
            }

            [PPNotification notifyWithMessage:message
                                      success:success
                                      updated:updated
                                        delay:seconds];

            [[Mixpanel sharedInstance] track:@"Added to read later" properties:@{@"Service": @"Native Reading List"}];
            break;
        }
            
        case PPReadLaterNone:
            completion();
            break;
    }
}

@end

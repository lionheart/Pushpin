//
//  PPUtilities.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/14/14.
//
//

#import "PPUtilities.h"

#import <SafariServices/SafariServices.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>
#import <PocketAPI/PocketAPI.h>
#import <oauthconsumer/OAuthConsumer.h>
#import <HTMLParser/HTMLParser.h>
#import <MWFeedParser/NSString+HTML.h>

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
                message = NSLocalizedString(@"Error adding to Reading List", nil);
            }
            else {
                message = NSLocalizedString(@"Added to Reading List", nil);
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

+ (NSMutableSet *)staticAssetURLsForHTML:(NSString *)html {
    NSMutableSet *assets = [NSMutableSet set];

    if (html) {
        // Retrieve all assets and queue them for download. Use a set to prevent duplicates.
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<img [^><]*src=['\"]([^'\"]+)['\"]" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
        NSCharacterSet *charactersToTrim = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        for (NSTextCheckingResult *result in matches) {
            if ([result numberOfRanges] > 1) {
                NSString *imageURLString = [html substringWithRange:[result rangeAtIndex:1]];
                imageURLString = [imageURLString stringByDecodingHTMLEntities];
                imageURLString = [imageURLString stringByTrimmingCharactersInSet:charactersToTrim];
                [assets addObject:imageURLString];
            }
        }

        regex = [NSRegularExpression regularExpressionWithPattern:@"<link [^><]*href=['\"]([^'\"]+\\.css)['\"]" options:NSRegularExpressionCaseInsensitive error:nil];
        matches = [regex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
        for (NSTextCheckingResult *result in matches) {
            if ([result numberOfRanges] > 1) {
                NSString *cssURLString = [html substringWithRange:[result rangeAtIndex:1]];
                cssURLString = [cssURLString stringByDecodingHTMLEntities];
                cssURLString = [cssURLString stringByTrimmingCharactersInSet:charactersToTrim];
                [assets addObject:cssURLString];
            }
        }
    }

    return assets;
}

+ (NSMutableSet *)staticAssetURLsForCachedURLResponse:(NSCachedURLResponse *)cachedURLResponse {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)cachedURLResponse.response;
    BOOL isHTMLResponse = [[httpResponse allHeaderFields][@"Content-Type"] rangeOfString:@"text/html"].location != NSNotFound;

    // If a static asset 404s, we do this to prevent recursion.
    BOOL isSuccessfulResponse = httpResponse.statusCode != 404;
    if (isHTMLResponse && isSuccessfulResponse) {
        return [self staticAssetURLsForHTML:[[NSString alloc] initWithData:cachedURLResponse.data encoding:NSUTF8StringEncoding]];
    }
    else {
        return [NSMutableSet set];
    }
}

+ (void)retrievePageTitle:(NSURL *)url callback:(void (^)(NSString *title, NSString *description))callback {
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [UIApplication lhs_setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [UIApplication lhs_setNetworkActivityIndicatorVisible:NO];
                               
                               NSString *description = @"";
                               NSString *title = @"";
                               if (!error) {
                                   HTMLParser *parser = [[HTMLParser alloc] initWithData:data error:&error];
                                   
                                   if (!error) {
                                       NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                                       
                                       HTMLNode *root = [parser head];
                                       HTMLNode *titleTag = [root findChildTag:@"title"];
                                       NSArray *metaTags = [root findChildTags:@"meta"];
                                       for (HTMLNode *tag in metaTags) {
                                           if ([[tag getAttributeNamed:@"name"] isEqualToString:@"description"]) {
                                               description = [[tag getAttributeNamed:@"content"] stringByTrimmingCharactersInSet:whitespace];
                                               break;
                                           }
                                       }
                                       
                                       if (titleTag && titleTag.contents) {
                                           title = [titleTag.contents stringByTrimmingCharactersInSet:whitespace];
                                       }
                                   }
                               }
                               
                               callback(title, description);
                           }];
}

+ (NSString *)databasePath {
#ifdef DELICIOUS
    NSString *pathComponent = @"/delicious.db";
#endif
    
#ifdef PINBOARD
    NSString *pathComponent = @"/pinboard.db";
#endif
    
#if TARGET_IPHONE_SIMULATOR
    return [@"/tmp" stringByAppendingString:pathComponent];
#else
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        return [paths[0] stringByAppendingPathComponent:pathComponent];
    }
    else {
        return pathComponent;
    }
#endif
}

+ (FMDatabaseQueue *)databaseQueue {
    static dispatch_once_t onceToken;
    static FMDatabaseQueue *queue;
    dispatch_once(&onceToken, ^{
        queue = [FMDatabaseQueue databaseQueueWithPath:[self databasePath]];
    });
    return queue;
}

+ (void)resetDatabase {
    [[self databaseQueue] close];

    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[self databasePath]];
    if (exists) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[self databasePath] error:nil];
    }
}

+ (void)migrateDatabase {
    PPSettings *settings = [PPSettings sharedSettings];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Create the database if it does not yet exist.
        FMDatabase *db = [FMDatabase databaseWithPath:[self databasePath]];
        [db open];
        [db close];
        
        [[self databaseQueue] inDatabase:^(FMDatabase *db) {
            // http://stackoverflow.com/a/875422/39155
            [db executeUpdate:@"PRAGMA cache_size=100;"];
            
            // http://stackoverflow.com/a/875422/39155
            [db executeUpdate:@"PRAGMA syncronous=OFF;"];
            
            FMResultSet *s = [db executeQuery:@"PRAGMA user_version"];
            BOOL success = [s next];
            if (success) {
                int version = [s intForColumnIndex:0];
                [s close];
                
                [db beginTransaction];
                
                switch (version) {
#ifdef DELICIOUS
                    case 0:
                        [db executeUpdate:
                         @"CREATE TABLE feeds("
                         "components TEXT UNIQUE,"
                         "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                         ");"];
                        
                        [db executeUpdate:
                         @"CREATE TABLE rejected_bookmark("
                         "url TEXT UNIQUE CHECK(length(url) < 2000),"
                         "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                         ");"];
                        [db executeUpdate:@"CREATE INDEX rejected_bookmark_url_idx ON rejected_bookmark (url);"];
                        
                        [db executeUpdate:
                         @"CREATE TABLE bookmark("
                         "title TEXT,"
                         "description TEXT,"
                         "tags TEXT,"
                         "url TEXT,"
                         "count INTEGER,"
                         "private BOOL,"
                         "unread BOOL,"
                         "hash VARCHAR(32) UNIQUE,"
                         "meta VARCHAR(32),"
                         "created_at DATETIME"
                         ");" ];
                        
                        [db executeUpdate:@"CREATE INDEX bookmark_created_at_idx ON bookmark (created_at);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_private_idx ON bookmark (private);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_unread_idx ON bookmark (unread);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_url_idx ON bookmark (url);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_hash_idx ON bookmark (hash);"];
                        
                        [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(hash, title, description, tags, url, prefix='2,3,4,5,6');"];
                        [db executeUpdate:@"CREATE VIRTUAL TABLE tag_fts USING fts4(id, name, prefix='2,3,4,5');"];
                        
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (hash, title, description, tags, url) VALUES(new.hash, new.title, new.description, new.tags, new.url); END;"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags, url=new.url WHERE hash=new.hash AND old.meta != new.meta; END;"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_delete_trigger AFTER DELETE ON bookmark BEGIN DELETE FROM bookmark_fts WHERE hash=old.hash; END;"];
                        
                        // Tagging
                        [db executeUpdate:
                         @"CREATE TABLE tag("
                         "name TEXT UNIQUE,"
                         "count INTEGER"
                         ");" ];
                        
                        [db executeUpdate:@"CREATE INDEX tag_name_idx ON tag (name);"];
                        
                        [db executeUpdate:
                         @"CREATE TABLE tagging("
                         "tag_name TEXT,"
                         "bookmark_hash TEXT"
                         ");" ];
                        
                        [db executeUpdate:@"CREATE INDEX tagging_tag_name_idx ON tagging (tag_name);"];
                        [db executeUpdate:@"CREATE INDEX tagging_bookmark_hash_idx ON tagging (bookmark_hash);"];
                        
                        [db executeUpdate:@"CREATE TRIGGER tag_fts_insert_trigger AFTER INSERT ON tag BEGIN INSERT INTO tag_fts (name) VALUES(new.name); END;"];
                        [db executeUpdate:@"CREATE TRIGGER tag_fts_delete_trigger AFTER DELETE ON tag BEGIN DELETE FROM tag_fts WHERE name=old.name; END;"];
                        
                        [db executeUpdate:@"PRAGMA user_version=1;"];
                        
                    default:
                        break;
#endif
                        
#ifdef PINBOARD
                    case 0:
                        [db executeUpdate:
                         @"CREATE TABLE bookmark("
                         "id INTEGER PRIMARY KEY ASC,"
                         "title VARCHAR(255),"
                         "description TEXT,"
                         "tags TEXT,"
                         "url TEXT UNIQUE CHECK(length(url) < 2000),"
                         "count INTEGER,"
                         "private BOOL,"
                         "unread BOOL,"
                         "hash VARCHAR(32) UNIQUE,"
                         "meta VARCHAR(32),"
                         "created_at DATETIME"
                         ");" ];
                        [db executeUpdate:
                         @"CREATE TABLE tag("
                         "id INTEGER PRIMARY KEY ASC,"
                         "name VARCHAR(255) UNIQUE,"
                         "count INTEGER"
                         ");" ];
                        [db executeUpdate:
                         @"CREATE TABLE tagging("
                         "tag_id INTEGER,"
                         "bookmark_id INTEGER,"
                         "PRIMARY KEY (tag_id, bookmark_id),"
                         "FOREIGN KEY (tag_id) REFERENCES tag (id) ON DELETE CASCADE,"
                         "FOREIGN KEY (bookmark_id) REFERENCES bookmark (id) ON DELETE CASCADE"
                         ");" ];
                        [db executeUpdate:
                         @"CREATE TABLE note("
                         "id INTEGER PRIMARY KEY ASC,"
                         "remote_id VARCHAR(20) UNIQUE,"
                         "hash VARCHAR(20) UNIQUE,"
                         "title VARCHAR(255),"
                         "text TEXT,"
                         "length INTEGER,"
                         "created_at DATETIME,"
                         "updated_at DATETIME"
                         ");" ];
                        
                        // Full text search
                        [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(id, title, description, tags);"];
                        [db executeUpdate:@"CREATE VIRTUAL TABLE note_fts USING fts4(id, title, text);"];
                        [db executeUpdate:@"CREATE VIRTUAL TABLE tag_fts USING fts4(id, name);"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (id, title, description, tags) VALUES(new.id, new.title, new.description, new.tags); END;"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags WHERE id=new.id; END;"];
                        [db executeUpdate:@"CREATE TRIGGER note_fts_insert_trigger AFTER INSERT ON note BEGIN INSERT INTO note_fts (id, title, text) VALUES(new.id, new.title, new.text); END;"];
                        [db executeUpdate:@"CREATE TRIGGER note_fts_update_trigger AFTER UPDATE ON note BEGIN UPDATE note_fts SET title=new.title, description=new.text WHERE id=new.id; END;"];
                        [db executeUpdate:@"CREATE TRIGGER tag_fts_insert_trigger AFTER INSERT ON tag BEGIN INSERT INTO tag_fts (id, name) VALUES(new.id, new.name); END;"];
                        [db executeUpdate:@"CREATE TRIGGER tag_fts_update_trigger AFTER UPDATE ON tag BEGIN UPDATE tag_fts SET name=new.name WHERE id=new.id; END;"];
                        
                        [db executeUpdate:@"CREATE INDEX bookmark_title_idx ON bookmark (title);"];
                        [db executeUpdate:@"CREATE INDEX note_title_idx ON note (title);"];
                        
                        // Has no effect here
                        // [db executeUpdate:@"PRAGMA foreign_keys=1;"];
                        
                        [db executeUpdate:@"PRAGMA user_version=1;"];
                        
                    case 1:
                        [db executeUpdate:@"UPDATE tag SET count=(SELECT COUNT(*) FROM tagging WHERE tag_id=tag.id)"];
                        [db executeUpdate:@"PRAGMA user_version=2;"];
                        
                    case 2:
                        settings.readLater = PPReadLaterNone;
                        [db executeUpdate:@"CREATE TABLE rejected_bookmark(url TEXT UNIQUE CHECK(length(url) < 2000));"];
                        [db executeUpdate:@"CREATE INDEX rejected_bookmark_url_idx ON rejected_bookmark (url);"];
                        [db executeUpdate:@"CREATE INDEX tag_name_idx ON tag (name);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_hash_idx ON bookmark (hash);"];
                        [db executeUpdate:@"PRAGMA user_version=3;"];
                        
                    case 3:
                        [db executeUpdate:@"ALTER TABLE rejected_bookmark RENAME TO rejected_bookmark_old;"];
                        [db executeUpdate:
                         @"CREATE TABLE rejected_bookmark("
                         "url TEXT UNIQUE CHECK(length(url) < 2000),"
                         "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                         ");"];
                        [db executeUpdate:@"INSERT INTO rejected_bookmark (url) SELECT url FROM rejected_bookmark_old;"];
                        [db executeUpdate:@"DROP TABLE rejected_bookmark_old;"];
                        
                        [db executeUpdate:@"ALTER TABLE bookmark ADD COLUMN starred BOOL DEFAULT 0;"];
                        [db executeUpdate:@"CREATE INDEX bookmark_starred_idx ON bookmark (starred);"];
                        [db executeUpdate:@"PRAGMA user_version=4;"];
                        
                    case 4:
                        [db executeUpdate:
                         @"CREATE TABLE feeds("
                         "components TEXT UNIQUE,"
                         "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                         ");"];
                        [db executeUpdate:@"PRAGMA user_version=5;"];
                        
                    case 5:
                        [db closeOpenResultSets];
                        [db executeUpdate:@"CREATE INDEX bookmark_created_at_idx ON bookmark (created_at);"];
                        [db executeUpdate:@"DROP INDEX bookmark_hash_idx"];
                        [db executeUpdate:@"PRAGMA user_version=6;"];
                        
                    case 6:
                        [db closeOpenResultSets];
                        [db executeUpdate:@"ALTER TABLE bookmark RENAME TO bookmark_old;"];
                        [db executeUpdate:@"ALTER TABLE tagging RENAME TO tagging_old;"];
                        [db executeUpdate:@"ALTER TABLE tag RENAME TO tag_old;"];
                        
                        [db executeUpdate:@"DROP INDEX bookmark_created_at_idx"];
                        [db executeUpdate:@"DROP INDEX bookmark_starred_idx"];
                        [db executeUpdate:@"DROP INDEX bookmark_title_idx"];
                        [db executeUpdate:
                         @"CREATE TABLE bookmark("
                         "title TEXT,"
                         "description TEXT,"
                         "tags TEXT,"
                         "url TEXT,"
                         "count INTEGER,"
                         "private BOOL,"
                         "unread BOOL,"
                         "starred BOOL,"
                         "hash VARCHAR(32) UNIQUE,"
                         "meta VARCHAR(32),"
                         "created_at DATETIME"
                         ");" ];
                        [db executeUpdate:@"CREATE INDEX bookmark_created_at_idx ON bookmark (created_at);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_starred_idx ON bookmark (starred);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_private_idx ON bookmark (private);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_unread_idx ON bookmark (unread);"];
                        [db executeUpdate:@"CREATE INDEX bookmark_url_idx ON bookmark (url);"];
                        
                        // Tag
                        [db executeUpdate:@"DROP TRIGGER tag_fts_insert_trigger;"];
                        [db executeUpdate:@"DROP TRIGGER tag_fts_update_trigger;"];
                        
                        [db executeUpdate:
                         @"CREATE TABLE tag("
                         "name TEXT UNIQUE,"
                         "count INTEGER"
                         ");" ];
                        
                        [db executeUpdate:@"CREATE TRIGGER tag_fts_insert_trigger AFTER INSERT ON tag BEGIN INSERT INTO tag_fts (name) VALUES(new.name); END;"];
                        [db executeUpdate:@"CREATE TRIGGER tag_fts_delete_trigger AFTER DELETE ON tag BEGIN DELETE FROM tag_fts WHERE name=old.name; END;"];
                        [db executeUpdate:@"INSERT INTO tag (name, count) SELECT name, count FROM tag_old;"];
                        
                        // Tagging
                        [db executeUpdate:
                         @"CREATE TABLE tagging("
                         "tag_name TEXT,"
                         "bookmark_hash TEXT"
                         ");" ];
                        
                        [db executeUpdate:@"INSERT INTO tagging (tag_name, bookmark_hash) SELECT tag_old.name, bookmark_old.hash FROM bookmark_old, tagging_old, tag_old WHERE tagging_old.bookmark_id=bookmark_old.id AND tagging_old.tag_id=tag_old.id"];
                        [db executeUpdate:@"CREATE INDEX tagging_tag_name_idx ON tagging (tag_name);"];
                        [db executeUpdate:@"CREATE INDEX tagging_bookmark_hash_idx ON tagging (bookmark_hash);"];
                        
                        // FTS Updates
                        [db executeUpdate:@"DROP TRIGGER bookmark_fts_insert_trigger;"];
                        [db executeUpdate:@"DROP TRIGGER bookmark_fts_update_trigger;"];
                        [db executeUpdate:@"DROP TRIGGER bookmark_fts_delete_trigger;"];
                        [db executeUpdate:@"DROP TABLE bookmark_fts;"];
                        
                        [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(hash, title, description, tags, url);"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (hash, title, description, tags, url) VALUES(new.hash, new.title, new.description, new.tags, new.url); END;"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags, url=new.url WHERE hash=new.hash AND old.meta != new.meta; END;"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_delete_trigger AFTER DELETE ON bookmark BEGIN DELETE FROM bookmark_fts WHERE hash=old.hash; END;"];
                        
                        [db commit];
                        [db beginTransaction];
                        // Repopulate bookmarks
                        [db executeUpdate:@"INSERT INTO bookmark (title, description, tags, url, count, private, unread, starred, hash, meta, created_at) SELECT title, description, tags, url, count, private, unread, starred, hash, meta, created_at FROM bookmark_old;"];
                        
                        [db executeUpdate:@"DROP TABLE tagging_old;"];
                        [db executeUpdate:@"DROP TABLE tag_old;"];
                        [db executeUpdate:@"DROP TABLE bookmark_old;"];
                        [db executeUpdate:@"PRAGMA user_version=7;"];
                        
                    case 7:
                        [db closeOpenResultSets];
                        
                        [db executeUpdate:@"CREATE INDEX bookmark_hash_idx ON bookmark (hash);"];
                        
                        // FTS Updates
                        [db executeUpdate:@"DROP TRIGGER bookmark_fts_insert_trigger;"];
                        [db executeUpdate:@"DROP TRIGGER bookmark_fts_update_trigger;"];
                        [db executeUpdate:@"DROP TRIGGER bookmark_fts_delete_trigger;"];
                        [db executeUpdate:@"DROP TABLE bookmark_fts;"];
                        
                        [db executeUpdate:@"CREATE VIRTUAL TABLE bookmark_fts USING fts4(hash, title, description, tags, url, prefix='2,3,4,5,6');"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_insert_trigger AFTER INSERT ON bookmark BEGIN INSERT INTO bookmark_fts (hash, title, description, tags, url) VALUES(new.hash, new.title, new.description, new.tags, new.url); END;"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_update_trigger AFTER UPDATE ON bookmark BEGIN UPDATE bookmark_fts SET title=new.title, description=new.description, tags=new.tags, url=new.url WHERE hash=new.hash AND old.meta != new.meta; END;"];
                        [db executeUpdate:@"CREATE TRIGGER bookmark_fts_delete_trigger AFTER DELETE ON bookmark BEGIN DELETE FROM bookmark_fts WHERE hash=old.hash; END;"];
                        
                        // Repopulate bookmarks
                        [db executeUpdate:@"INSERT INTO bookmark_fts (hash, title, description, tags, url) SELECT hash, title, description, tags, url FROM bookmark;"];
                        [db executeUpdate:@"PRAGMA user_version=8;"];
                        
                    case 8:
                        [db executeUpdate:@"DELETE FROM tagging WHERE tag_name='';"];
                        [db executeUpdate:@"PRAGMA user_version=9;"];
                        
                    case 9: {
                        NSArray *communityFeedOrder = settings.communityFeedOrder;
                        settings.communityFeedOrder = [communityFeedOrder arrayByAddingObject:@(PPPinboardCommunityFeedRecent)];
                        [db executeUpdate:@"PRAGMA user_version=10;"];
                    }
                        
                    case 10: {
                        // We set these so that these values sync to the extensions.
                        settings.readByDefault = settings.readByDefault;
                        settings.privateByDefault = settings.privateByDefault;
                        [db executeUpdate:@"PRAGMA user_version=11;"];
                    }
                        
                    case 11: {
                        [db executeUpdate:
                         @"CREATE TABLE searches("
                         "name TEXT UNIQUE,"
                         "query TEXT UNIQUE,"
                         "private INTEGER,"
                         "unread INTEGER,"
                         "starred INTEGER,"
                         "tagged INTEGER,"
                         "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                         ");" ];

                        [db executeUpdate:@"PRAGMA user_version=12;"];
                    }

                    default:
                        break;
#endif
                }
                
                [db commit];
            }
            else {
                [s close];
            }
        }];
    });
}

@end

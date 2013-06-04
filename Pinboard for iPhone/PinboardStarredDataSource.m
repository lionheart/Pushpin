//
//  PinboardStarredDataSource.m
//  Pushpin
//
//  Created by Dan Loewenherz on 6/4/13.
//
//

#import "PinboardStarredDataSource.h"

@implementation PinboardStarredDataSource

- (void)updateLocalDatabaseFromRemoteAPIWithSuccess:(void (^)())success failure:(void (^)())failure progress:(void (^)(NSInteger, NSInteger))progress options:(NSDictionary *)options {
    void (^BookmarksSuccessBlock)(NSArray *) = ^(NSArray *posts) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *oldURLs = [NSMutableArray array];
            NSUInteger index = 0;
            NSInteger skipPivot = 0;
            BOOL postFound = NO;
            NSString *url;

            FMDatabase *db = [FMDatabase databaseWithPath:[AppDelegate databasePath]];
            [db open];
            [db beginTransaction];
            
            FMResultSet *results = [db executeQuery:@"SELECT url FROM bookmark WHERE starred=1"];
            while ([results next]) {
                url = [results stringForColumnIndex:0];
                [oldURLs addObject:url];
            }
            
            for (NSDictionary *post in posts) {
                postFound = NO;
                url = post[@"u"];
                
                for (NSInteger i=skipPivot; i<oldURLs.count; i++) {
                    if ([oldURLs[i] isEqualToString:url]) {
                        // Delete all posts that were skipped
                        for (NSInteger j=skipPivot; j<i; j++) {
                            [db executeUpdate:@"UPDATE bookmark SET starred=0 WHERE url=?" withArgumentsInArray:@[oldURLs[j]]];
                        }
                        
                        skipPivot = i + 1;
                        postFound = YES;
                        break;
                    }
                }
                
                if (!postFound && ![oldURLs containsObject:url]) {
                    [db executeUpdate:@"UPDATE bookmark SET starred=1 WHERE url=?" withArgumentsInArray:@[url]];
                }
                
                index++;
            }
            [db commit];
            [db close];

            success();
        });
    };
    
    if (!failure) {
        failure = ^{};
    }
    
    NSString *username = [[[[AppDelegate sharedDelegate] token] componentsSeparatedByString:@":"] objectAtIndex:0];
    NSString *feedToken = [[AppDelegate sharedDelegate] feedToken];
    NSURL *endpoint = [NSURL URLWithString:[NSString stringWithFormat:@"https://feeds.pinboard.in/json/secret:%@/u:%@/starred/?count=400", feedToken, username]];
    NSURLRequest *request = [NSURLRequest requestWithURL:endpoint];
    AppDelegate *delegate = [AppDelegate sharedDelegate];
    [delegate setNetworkActivityIndicatorVisible:YES];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [delegate setNetworkActivityIndicatorVisible:NO];
                               if (error) {
                                   failure(error);
                               }
                               else {
                                   NSArray *posts = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                                   BookmarksSuccessBlock(posts);
                               }
                           }];
}

- (void)updatePostsWithSuccess:(void (^)(NSArray *, NSArray *, NSArray *))success failure:(void (^)(NSError *))failure options:(NSDictionary *)options {
    [self updateLocalDatabaseFromRemoteAPIWithSuccess:^{
        [self updatePostsFromDatabaseWithSuccess:success failure:failure];
    } failure:failure progress:nil options:options];
}

@end

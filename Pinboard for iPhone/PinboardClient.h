//
//  PinboardClient.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AFHTTPClient.h"

@interface PinboardClient : AFHTTPClient
+ (PinboardClient *)sharedClient;
- (id)initWithBaseURL:(NSURL *)url;
- (id)initWithBaseURL:(NSURL *)url username:(NSString *)username password:(NSString *)password;
- (void)path:(NSString *)path
  parameters:(NSDictionary *)parameters 
     success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
     failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure;

- (void)path:(NSString *)path
     success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
     failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure;

@end
